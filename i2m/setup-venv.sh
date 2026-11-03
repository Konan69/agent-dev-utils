#!/bin/bash
if [[ ${1:-} == --help ]]; then
  echo 'Usage: setup-venv.sh'
  echo 'I2M_ROOT defaults to this script directory. Upstream checkouts, licenses, uv, CUDA and model weights are required.'
  exit 0
fi
export I2M_ROOT="${I2M_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# Root cause of the stalls: long transfers from pypi.nvidia.com are cut mid-file from here, and uv
# restarts a cut wheel from byte 0, so the 255 MB cusolver wheel never finishes. curl -C - resumes
# from where the cut happened; uv then installs that wheel from disk (--find-links).
export UV_HTTP_TIMEOUT=900 UV_CONCURRENT_DOWNLOADS=2 UV_HTTP_RETRIES=8
cd "$I2M_ROOT"; [ -d venv ] || uv venv -q -p 3.10 venv
source venv/bin/activate; mkdir -p wheels
fetch(){ local url=$1 sha=$2 f=wheels/$(basename "$1"); until echo "$sha  $f" | sha256sum -c --status 2>/dev/null; do curl -sS -L -C - --retry 20 --retry-all-errors --speed-limit 50000 --speed-time 30 -o "$f" "$url" || sleep 3; done; echo "fetched $f"; }
fetch https://pypi.nvidia.com/nvidia-cusolver-cu12/nvidia_cusolver_cu12-11.7.3.90-py3-none-manylinux_2_27_x86_64.whl 4376c11ad263152bd50ea295c05370360776f8c3427b30991df774f9fb26c450
try(){ for i in $(seq 1 12); do "$@" && return 0; echo "retry $i: $*"; sleep 15; done; return 1; }
try uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128 --find-links wheels || exit 1
try uv pip install -q -r Hunyuan3D-2/requirements.txt || exit 1
python3 -c "import torch;print('TORCH', torch.__version__, torch.cuda.is_available(), torch.cuda.get_device_capability())"
echo VENV-DONE
