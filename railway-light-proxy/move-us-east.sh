#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: move-us-east.sh; requires RAILWAY_SERVICE_ID; changes region and restarts proxy'
  exit 0
fi
: "${RAILWAY_SERVICE_ID:?Set RAILWAY_SERVICE_ID}"
cd "$(dirname "${BASH_SOURCE[0]}")"
cat > /tmp/region-us-east.json <<JSON
{
  "services": {
    "${RAILWAY_SERVICE_ID}": {
      "deploy": {
        "multiRegionConfig": {
          "us-east4-eqdc4a": { "numReplicas": 1 }
        }
      }
    }
  }
}
JSON
railway environment edit --json < /tmp/region-us-east.json
railway service restart --service proxy
