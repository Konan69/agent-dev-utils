import sys
if "--help" in sys.argv:
    print("Usage: python3 fetch-rest.py ")
    sys.exit(0)
"""Hunyuan3D-2 paint + delight and the InstantMesh UNet: the two the CLI run skipped.
Resumable: snapshot_download skips finished files and resumes partial ones."""
import os
from pathlib import Path
from huggingface_hub import snapshot_download

os.environ["HF_HUB_DISABLE_TELEMETRY"] = "1"
W = str(Path(os.environ.get("I2M_ROOT", Path(__file__).resolve().parent)) / "weights")
snapshot_download(
    "tencent/Hunyuan3D-2",
    local_dir=f"{W}/tencent_Hunyuan3D-2",
    allow_patterns=["hunyuan3d-paint-v2-0-turbo/**", "hunyuan3d-delight-v2-0/**"],
    ignore_patterns=["hunyuan3d-paint-v2-0-turbo/unet/diffusion_pytorch_model.bin"],
    max_workers=4,
)
print("HY-PAINT-DONE", flush=True)
snapshot_download(
    "TencentARC/InstantMesh",
    local_dir=f"{W}/TencentARC_InstantMesh",
    allow_patterns=["diffusion_pytorch_model.bin", "instant_mesh_large.ckpt"],
    max_workers=2,
)
print("IM-DONE", flush=True)
print("WEIGHTS-DONE", flush=True)
