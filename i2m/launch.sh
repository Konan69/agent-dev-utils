#!/bin/bash
if [[ ${1:-} == --help ]]; then
  echo 'Usage: launch.sh'
  echo 'I2M_ROOT defaults to this script directory. Upstream checkouts, licenses, uv, CUDA and model weights are required.'
  exit 0
fi
export I2M_ROOT="${I2M_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# Start the installers and the waiter as systemd user units. T3 runs each agent in its own scope
# (app-t3code-agents.slice/...scope) and a T3 restart kills the whole scope, setsid children
# included; a transient unit lives in its own cgroup, so it survives that. Every step is
# idempotent (uv cache, hf resume, done/ markers), so starting a unit again only redoes what is left.
cd "$I2M_ROOT"
mkdir -p logs
for s in setup-venv-im waiter; do
  unit=i2m-$s
  systemctl --user is-active --quiet $unit && { echo "running $unit"; continue; }
  systemctl --user reset-failed $unit 2>/dev/null
  systemd-run --user --quiet --unit=$unit -p Restart=on-failure -p RestartSec=30 --working-directory="$I2M_ROOT" \
    --setenv=I2M_ROOT="$I2M_ROOT" --setenv=I2M_INPUT="${I2M_INPUT:-}" \
    --setenv=I2M_OUTPUT="${I2M_OUTPUT:-}" --setenv=I2M_RENDER_SCRIPT="${I2M_RENDER_SCRIPT:-}" \
    --setenv=PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin \
    bash -c "./$s.sh > logs/${s#setup-}.log 2>&1 < /dev/null"
  echo "started $unit"
done
