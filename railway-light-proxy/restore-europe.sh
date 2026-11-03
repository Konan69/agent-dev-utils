#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: restore-europe.sh; requires RAILWAY_SERVICE_ID; changes region and redeploys proxy'
  exit 0
fi
: "${RAILWAY_SERVICE_ID:?Set RAILWAY_SERVICE_ID}"
cd "$(dirname "${BASH_SOURCE[0]}")"
cat > /tmp/region-europe.json <<JSON
{
  "services": {
    "${RAILWAY_SERVICE_ID}": {
      "deploy": {
        "multiRegionConfig": {
          "europe-west4-drams3a": { "numReplicas": 1 }
        }
      }
    }
  }
}
JSON
railway environment edit --json < /tmp/region-europe.json
railway redeploy --service proxy --yes
sleep 25
railway service status --service proxy --json
