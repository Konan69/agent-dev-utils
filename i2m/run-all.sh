#!/bin/bash
if [[ ${1:-} == --help ]]; then
  echo 'Usage: run-all.sh (set I2M_INPUT, I2M_OUTPUT, I2M_RENDER_SCRIPT)'
  echo 'I2M_ROOT defaults to this script directory. Upstream checkouts, licenses, uv, CUDA and model weights are required.'
  exit 0
fi
export I2M_ROOT="${I2M_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# Build the CUDA extensions and run every tool on the accepted drawing. Each step leaves a marker
# in done/ so a rerun after a crash skips what already finished.
set -u
SRC=${I2M_INPUT:?set I2M_INPUT to an RGBA image}
OUT=${I2M_OUTPUT:?set I2M_OUTPUT to an output directory}
RENDER=${I2M_RENDER_SCRIPT:?set I2M_RENDER_SCRIPT to a Blender render script}
cd "$I2M_ROOT"; mkdir -p done logs
export CUDA_HOME=/usr/local/cuda-12.8 PATH=/usr/local/cuda-12.8/bin:$PATH TORCH_CUDA_ARCH_LIST="12.0"
source venv/bin/activate; uv pip install -q setuptools wheel ninja pybind11 >/dev/null; (source venv-im/bin/activate 2>/dev/null && uv pip install -q setuptools wheel ninja >/dev/null)
step(){ local name=$1; shift; [ -f done/$name ] && { echo "skip $name"; return 0; }; echo "== $name"; if "$@" > logs/$name.log 2>&1; then touch done/$name; echo "ok $name"; else echo "FAIL $name: $(tail -c 400 logs/$name.log)"; fi; }

step rasterizer bash -c 'cd Hunyuan3D-2/hy3dgen/texgen/custom_rasterizer && uv pip install -q --no-build-isolation .'
step meshproc bash -c 'cd Hunyuan3D-2/hy3dgen/texgen/differentiable_renderer && uv pip install -q --no-build-isolation .'
step hy python3 hy-run.py $SRC $OUT/hunyuan/hunyuan.glb
step hy-render bash -c "~/.local/bin/blender -b --python $RENDER -- $OUT/hunyuan/hunyuan.glb $OUT/hunyuan/render | grep RENDERED"

step diso uv pip install -q --no-build-isolation diso
step triposg-deps uv pip install -q peft jaxtyping typeguard scikit-image
step triposg bash -c "cd TripoSG && ln -sfn $I2M_ROOT/weights/VAST-AI_TripoSG pretrained_weights/TripoSG 2>/dev/null; mkdir -p pretrained_weights; ln -sfn $I2M_ROOT/weights/VAST-AI_TripoSG pretrained_weights/TripoSG; PYTHONPATH=\$PWD python3 scripts/inference_triposg.py --image-input $SRC --output-path $OUT/triposg/triposg.glb --faces 40000"
step triposg-render bash -c "~/.local/bin/blender -b --python $RENDER -- $OUT/triposg/triposg.glb $OUT/triposg/render | grep RENDERED"

step tha3-models bash -c 'mkdir -p talking-head-anime-3-demo/data/models && cp -rn weights/OktayAlpk_talking-head-anime-3/* talking-head-anime-3-demo/data/models/ && ls talking-head-anime-3-demo/data/models/standard_float'
step tha3 python3 tha3-pose.py $SRC $OUT/tha3

# InstantMesh runs in its own venv (pinned diffusers 0.20 / transformers 4.34).
step im-nvdiffrast bash -c 'source venv-im/bin/activate && uv pip install -q --no-build-isolation git+https://github.com/NVlabs/nvdiffrast/'
step im-ckpts bash -c 'cd InstantMesh && mkdir -p ckpts && for f in $I2M_ROOT/weights/TencentARC_InstantMesh/*; do ln -sfn $f ckpts/; done; ls ckpts'
step instantmesh bash -c "source venv-im/bin/activate && cd InstantMesh && python3 run.py configs/instant-mesh-large.yaml $SRC --output_path $OUT/instantmesh --export_texmap --no_rembg && ls -R $OUT/instantmesh | head"
step im-render bash -c "g=\$(find $OUT/instantmesh -name '*.obj' -o -name '*.glb' | head -1); ~/.local/bin/blender -b --python $RENDER -- \$g $OUT/instantmesh/render | grep RENDERED"
echo RUN-ALL-DONE
