import sys
if "--help" in sys.argv:
    print("Usage: python3 hy-run.py <rgba.png> <out.glb>")
    sys.exit(0)
"""Hunyuan3D-2 on one 8 GB GPU: mini-turbo shape, then paint-turbo texture, each loaded alone.

    python3 hy-run.py <rgba png> <out.glb>

Shape and paint are never resident together (the demo app's --low_vram_mode does the same by
moving pipelines between CPU and GPU); here the shape pipeline is dropped before paint loads.
"""
import sys, gc, os, torch
from pathlib import Path
from PIL import Image
sys.path.insert(0, str(Path(os.environ.get("I2M_ROOT", Path(__file__).resolve().parent)) / "Hunyuan3D-2"))
from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline, FaceReducer, FloaterRemover, DegenerateFaceRemover

W = Path(os.environ.get("I2M_ROOT", Path(__file__).resolve().parent)) / "weights"
src, out = sys.argv[1], Path(sys.argv[2]); out.parent.mkdir(parents=True, exist_ok=True)
image = Image.open(src).convert("RGBA")

shape = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(str(W / "tencent_Hunyuan3D-2mini"), subfolder="hunyuan3d-dit-v2-mini-turbo")
shape.enable_flashvdm()
mesh = shape(image=image, num_inference_steps=5, octree_resolution=256, generator=torch.manual_seed(1234))[0]
mesh = FloaterRemover()(mesh); mesh = DegenerateFaceRemover()(mesh); mesh = FaceReducer()(mesh, max_facenum=40000)
mesh.export(str(out.with_name(out.stem + "-shape.glb")))
print("SHAPE faces", len(mesh.faces), "vram", torch.cuda.max_memory_allocated() // 2**20, "MiB")
del shape; gc.collect(); torch.cuda.empty_cache(); torch.cuda.reset_peak_memory_stats()

# Imported here: texgen needs the CUDA extensions; the shape above is saved even if they are missing.
from hy3dgen.texgen import Hunyuan3DPaintPipeline
paint = Hunyuan3DPaintPipeline.from_pretrained(str(W / "tencent_Hunyuan3D-2"))
mesh = paint(mesh, image=image)
mesh.export(str(out))
print("TEXTURED", out, "vram", torch.cuda.max_memory_allocated() // 2**20, "MiB")
print("HY-DONE")
