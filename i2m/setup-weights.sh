#!/bin/bash
if [[ ${1:-} == --help ]]; then
  echo 'Usage: setup-weights.sh'
  echo 'I2M_ROOT defaults to this script directory. Upstream checkouts, licenses, uv, CUDA and model weights are required.'
  exit 0
fi
export I2M_ROOT="${I2M_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# Only the files each loader reads (safetensors where both exist; InstantMesh large only). ~27 GB.
# Shape models first so the first pass can run while the texture weights are still coming.
mkdir -p "$I2M_ROOT/weights"; cd "$I2M_ROOT/weights"; export HF_HUB_DISABLE_TELEMETRY=1
dl(){ uvx --from huggingface_hub hf download "$@" 2>&1 | tail -1; }
dl tencent/Hunyuan3D-2mini --include 'hunyuan3d-dit-v2-mini-turbo/config.yaml' 'hunyuan3d-dit-v2-mini-turbo/model.fp16.safetensors' --local-dir tencent_Hunyuan3D-2mini
dl VAST-AI/TripoSG --local-dir VAST-AI_TripoSG
dl OktayAlpk/talking-head-anime-3 --local-dir OktayAlpk_talking-head-anime-3
dl tencent/Hunyuan3D-2 --include 'hunyuan3d-paint-v2-0-turbo/*' 'hunyuan3d-delight-v2-0/*' --exclude 'hunyuan3d-paint-v2-0-turbo/unet/diffusion_pytorch_model.bin' --local-dir tencent_Hunyuan3D-2
dl TencentARC/InstantMesh --include 'diffusion_pytorch_model.bin' 'instant_mesh_large.ckpt' --local-dir TencentARC_InstantMesh
du -sh *; echo WEIGHTS-DONE
