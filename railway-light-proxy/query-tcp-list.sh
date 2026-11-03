#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: query-tcp-list.sh; requires RAILWAY_ENVIRONMENT_ID and RAILWAY_SERVICE_ID'
  exit 0
fi
: "${RAILWAY_SERVICE_ID:?Set RAILWAY_SERVICE_ID}"
: "${RAILWAY_ENVIRONMENT_ID:?Set RAILWAY_ENVIRONMENT_ID}"
TOKEN=${RAILWAY_TOKEN:-$(jq -r '.user.accessToken // .user.token // empty' ~/.railway/config.json)}
QUERY='query($environmentId:String!,$serviceId:String!){ tcpProxies(environmentId:$environmentId,serviceId:$serviceId){ id domain proxyPort applicationPort serviceId environmentId syncStatus } }'
VARS=$(jq -nc --arg e "$RAILWAY_ENVIRONMENT_ID" --arg s "$RAILWAY_SERVICE_ID" '{environmentId:$e,serviceId:$s}')
curl -sS https://backboard.railway.com/graphql/v2 \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  --data "$(jq -nc --arg q "$QUERY" --argjson v "$VARS" '{query:$q,variables:$v}')" | jq .
