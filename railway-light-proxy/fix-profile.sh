#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: fix-profile.sh; requires PROXY_HOST, PROXY_USER, PROXY_PASS; writes ~/.profile'
  exit 0
fi
source "${PROXY_CONFIG:-$(dirname "$(realpath "${BASH_SOURCE[0]}")")/config.sh}"
: "${PROXY_USER:?Set PROXY_USER in config.sh}"
: "${PROXY_PASS:?Set PROXY_PASS in config.sh}"
: "${PROXY_HOST:?Set PROXY_HOST in config.sh}"
cd "$HOME"
# Remove broken/old proxy exports, then append the current one without printing the secret.
if [ -f .profile ]; then
  grep -v 'RAILWAY_PROXY_URL\|^export$' .profile > .profile.tmp || true
  mv .profile.tmp .profile
fi
USER_VALUE=$PROXY_USER
PASS_VALUE=$PROXY_PASS
printf 'export RAILWAY_PROXY_URL="http://%s:%s@%s"\n' "$USER_VALUE" "$PASS_VALUE" "$PROXY_HOST" >> .profile
echo wsl-profile-configured
