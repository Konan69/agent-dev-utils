#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: check.sh; reads PROXY_HOST, PROXY_USER, PROXY_PASS and checks service status'
  exit 0
fi
cd "$(dirname "${BASH_SOURCE[0]}")"
sleep 25
railway service status --service proxy --json || true
railway logs --service proxy --lines 160 || true
set -a
source "${PROXY_CONFIG:-./config.sh}"
: "${PROXY_USER:?Set PROXY_USER in config.sh}"
: "${PROXY_PASS:?Set PROXY_PASS in config.sh}"
: "${PROXY_HOST:?Set PROXY_HOST in config.sh}"
set +a
echo
echo proxy-test
curl -sS --max-time 20 -x "http://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}" https://ifconfig.me || true
echo
