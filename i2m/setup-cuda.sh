#!/bin/bash
if [[ ${1:-} == --help ]]; then
  echo 'Usage: setup-cuda.sh'
  echo 'I2M_ROOT defaults to this script directory. Upstream checkouts, licenses, uv, CUDA and model weights are required.'
  exit 0
fi
export I2M_ROOT="${I2M_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
set -e; cd /tmp
[ -f /usr/local/cuda-12.8/bin/nvcc ] && { echo CUDA-DONE; exit 0; }
wget -q -N https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
sudo -n dpkg -i cuda-keyring_1.1-1_all.deb >/dev/null; sudo -n apt-get update -qq
sudo -n DEBIAN_FRONTEND=noninteractive apt-get install -y -qq cuda-toolkit-12-8
/usr/local/cuda-12.8/bin/nvcc --version | tail -1; echo CUDA-DONE
