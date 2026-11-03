#!/bin/bash
if [[ ${1:-} == --help ]]; then
  echo 'Usage: setup-venv-im.sh'
  echo 'I2M_ROOT defaults to this script directory. Upstream checkouts, licenses, uv, CUDA and model weights are required.'
  exit 0
fi
export I2M_ROOT="${I2M_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
export UV_HTTP_TIMEOUT=900 UV_CONCURRENT_DOWNLOADS=2 UV_HTTP_RETRIES=8
cd "$I2M_ROOT"
try(){ for i in $(seq 1 12); do "$@" && return 0; echo "retry $i"; sleep 15; done; return 1; }
[ -d venv-im ] || uv venv -q -p 3.10 venv-im
source venv-im/bin/activate
try uv pip install -q torch torchvision --index-url https://download.pytorch.org/whl/cu128
try uv pip install -q pytorch-lightning==2.1.2 einops omegaconf torchmetrics accelerate PyMCubes trimesh rembg "transformers==4.34.1" "diffusers==0.20.2" "huggingface-hub<0.26" "imageio[ffmpeg]" xatlas plyfile ninja numpy==1.26.4 opencv-python3-headless pillow
python3 -c "import torch, diffusers, transformers; print('TORCH', torch.__version__, torch.cuda.is_available())"
echo VENV-IM-DONE
