#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: test-tcp-proxy.sh; requires PROXY_HOST, PROXY_USER, PROXY_PASS; queries external IP'
  exit 0
fi
cd "$(dirname "${BASH_SOURCE[0]}")"
sleep 20
./query-tcp-list.sh
set -a
source "${PROXY_CONFIG:-./config.sh}"
: "${PROXY_USER:?Set PROXY_USER in config.sh}"
: "${PROXY_PASS:?Set PROXY_PASS in config.sh}"
: "${PROXY_HOST:?Set PROXY_HOST in config.sh}"
set +a
echo direct
curl -sS --max-time 20 https://ifconfig.me || true
echo
echo proxy
curl -sS --max-time 30 -x "http://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}" https://ifconfig.me || true
echo
