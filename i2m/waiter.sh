#!/bin/bash
if [[ ${1:-} == --help ]]; then
  echo 'Usage: waiter.sh (set I2M_INPUT, I2M_OUTPUT, I2M_RENDER_SCRIPT)'
  echo 'I2M_ROOT defaults to this script directory. Upstream checkouts, licenses, uv, CUDA and model weights are required.'
  exit 0
fi
export I2M_ROOT="${I2M_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# Run every tool as soon as its inputs exist: a pass after torch lands, another after CUDA and all weights.
cd "$I2M_ROOT"
until grep -q VENV-DONE logs/venv.log 2>/dev/null; do pgrep -f setup-venv.sh >/dev/null || { echo VENV-FAILED; tail -5 logs/venv.log; exit 1; }; sleep 20; done
echo "pass 1 $(date +%T)"; ./run-all.sh 2>&1 | grep -E "^(ok|FAIL|skip)" | cut -c1-300
until [ -f /usr/local/cuda-12.8/bin/nvcc ] && grep -q WEIGHTS-DONE logs/weights.log 2>/dev/null; do sleep 30; done
echo "pass 2 $(date +%T)"; ./run-all.sh 2>&1 | grep -E "^(ok|FAIL|skip)" | cut -c1-300
echo WAITER-DONE
