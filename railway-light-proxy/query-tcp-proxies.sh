#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: query-tcp-proxies.sh; requires RAILWAY_SERVICE_ID'
  exit 0
fi
: "${RAILWAY_SERVICE_ID:?Set RAILWAY_SERVICE_ID}"
TOKEN=${RAILWAY_TOKEN:-$(jq -r '.user.accessToken // .user.token // empty' ~/.railway/config.json)}
QUERY='query($id:String!){ service(id:$id){ id name tcpProxies { edges { node { id domain proxyPort applicationPort serviceId environmentId syncStatus } } } } }'
VARS=$(jq -nc --arg id "$RAILWAY_SERVICE_ID" '{id:$id}')
curl -sS https://backboard.railway.com/graphql/v2 \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  --data "$(jq -nc --arg q "$QUERY" --argjson v "$VARS" '{query:$q,variables:$v}')" | jq .
