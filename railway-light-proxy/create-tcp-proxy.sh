#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: create-tcp-proxy.sh; requires RAILWAY_SERVICE_ID; changes TCP networking'
  exit 0
fi
: "${RAILWAY_SERVICE_ID:?Set RAILWAY_SERVICE_ID}"
cd "$(dirname "${BASH_SOURCE[0]}")"
cat > /tmp/tcp-proxy-patch.json <<JSON
{
  "services": {
    "${RAILWAY_SERVICE_ID}": {
      "networking": {
        "tcpProxies": {
          "proxy-8080": {
            "applicationPort": 8080,
            "isCreated": true
          }
        }
      }
    }
  }
}
JSON
railway environment edit --json < /tmp/tcp-proxy-patch.json
railway environment config --json | jq --arg service "$RAILWAY_SERVICE_ID" '.services[$service].networking'
