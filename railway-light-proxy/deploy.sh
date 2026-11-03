#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: deploy.sh; requires PROXY_USER and PROXY_PASS; deploys service proxy'
  exit 0
fi
cd "$(dirname "${BASH_SOURCE[0]}")"
set -a
source "${PROXY_CONFIG:-./config.sh}"
: "${PROXY_USER:?Set PROXY_USER in config.sh}"
: "${PROXY_PASS:?Set PROXY_PASS in config.sh}"
set +a
railway variables --set "PROXY_USER=$PROXY_USER" --service proxy
railway variables --set "PROXY_PASS=$PROXY_PASS" --service proxy
railway variables --set "PORT=8080" --service proxy
railway up --detach --service proxy -m "Deploy lightweight authenticated proxy"
