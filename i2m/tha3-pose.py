import sys
if "--help" in sys.argv:
    print("Usage: python3 tha3-pose.py <rgba.png> <outdir>")
    sys.exit(0)
"""Headless Talking Head Anime 3: pose the accepted drawing at several yaws and expressions.

    python3 tha3-pose.py <rgba png> <outdir>

THA3 expects a 512x512 RGBA image with the head inside a 128x128 box centred in the top half
(README), so the 1024 head drawing is shrunk to that box on a transparent canvas; outputs are
cropped back to the head box and upscaled so they compare at the same size as the other tools.
"""
import sys, os
from pathlib import Path
import torch, numpy, PIL.Image
sys.path.insert(0, str(Path(os.environ.get("I2M_ROOT", Path(__file__).resolve().parent)) / "talking-head-anime-3-demo"))
os.chdir(Path(os.environ.get("I2M_ROOT", Path(__file__).resolve().parent)) / "talking-head-anime-3-demo")
from tha3.poser.modes.load_poser import load_poser
from tha3.util import extract_pytorch_image_from_PIL_image, rgba_to_numpy_image

src, out = Path(sys.argv[1]), Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
device = torch.device("cuda")
poser = load_poser("standard_float", device)
poser.get_modules()
size = poser.get_image_size()  # 512
# Head box: 128x128 centred in the top half, i.e. centre (256, 128).
head = PIL.Image.open(src).convert("RGBA")
bbox = head.getbbox(); head = head.crop(bbox)
box = 128
scale = box / max(head.size); head = head.resize((max(1, round(head.width*scale)), max(1, round(head.height*scale))), PIL.Image.LANCZOS)
canvas = PIL.Image.new("RGBA", (size, size), (0, 0, 0, 0))
canvas.paste(head, (256 - head.width//2, 128 - head.height//2), head)
canvas.save(out / "input-512.png")
image = extract_pytorch_image_from_PIL_image(canvas).to(device)

params = poser.get_pose_parameter_groups()
def idx(name):
    return poser.get_pose_parameter_index(name) if hasattr(poser, "get_pose_parameter_index") else [i for i, g in enumerate(params) if g.get_group_name() == name][0]
# Parameter index by name (poser.py PoseParameters.get_parameter_index walks groups by arity).
from tha3.poser.modes.pose_parameters import get_pose_parameters
pp = get_pose_parameters()
def P(name): return pp.get_parameter_index(name)
n = poser.get_num_parameters()

def render(name, **kw):
    pose = torch.zeros(n, device=device)
    for k, v in kw.items():
        i = P(k)
        if isinstance(v, (tuple, list)):
            for j, vv in enumerate(v): pose[i+j] = vv
        else: pose[i] = v
    with torch.no_grad():
        o = poser.pose(image, pose)[0].detach().cpu()
    arr = numpy.uint8(numpy.rint(rgba_to_numpy_image(o) * 255.0))
    im = PIL.Image.fromarray(arr, "RGBA")
    # Crop the head box with margin and upscale to 512 for the comparison board.
    im = im.crop((256-112, 128-112, 256+112, 128+112)).resize((512, 512), PIL.Image.LANCZOS)
    im.save(out / f"{name}.png"); print("wrote", name)

# head_y is yaw in [-1, 1]; THA3 trains to about ±15°, so 1.0 is its maximum turn.
render("yaw+00")
render("yaw-35", head_y=-0.5)
render("yaw+35", head_y=0.5)
render("yaw-70", head_y=-1.0)
render("yaw+70", head_y=1.0)
render("blink", eye_wink=(1.0, 1.0))
render("happy", eye_happy_wink=(1.0, 1.0), mouth_aaa=0.0, mouth_raised_corner=(1.0, 1.0))
render("surprised", eye_surprised=(1.0, 1.0), mouth_ooo=1.0, eyebrow_raised=(1.0, 1.0))
render("talk", mouth_aaa=1.0)
print("THA3-DONE")
