#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: fix-single-region.sh; requires RAILWAY_SERVICE_ID; deploys one Europe replica'
  exit 0
fi
: "${RAILWAY_SERVICE_ID:?Set RAILWAY_SERVICE_ID}"
cd "$(dirname "${BASH_SOURCE[0]}")"
cat > /tmp/remove-us-east.json <<JSON
{
  "services": {
    "${RAILWAY_SERVICE_ID}": {
      "deploy": {
        "multiRegionConfig": {
          "us-east4-eqdc4a": null,
          "europe-west4-drams3a": { "numReplicas": 1 }
        }
      }
    }
  }
}
JSON
railway environment edit --json < /tmp/remove-us-east.json
railway up --detach --service proxy -m "Restore single-region proxy"
sleep 30
railway service status --service proxy --json
