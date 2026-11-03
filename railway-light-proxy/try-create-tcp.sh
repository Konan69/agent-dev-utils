#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: try-create-tcp.sh; requires RAILWAY_ENVIRONMENT_ID and RAILWAY_SERVICE_ID; creates TCP proxy'
  exit 0
fi
: "${RAILWAY_SERVICE_ID:?Set RAILWAY_SERVICE_ID}"
: "${RAILWAY_ENVIRONMENT_ID:?Set RAILWAY_ENVIRONMENT_ID}"
TOKEN=${RAILWAY_TOKEN:-$(jq -r '.user.accessToken // .user.token // empty' ~/.railway/config.json)}
VARS=$(jq -nc --arg e "$RAILWAY_ENVIRONMENT_ID" --arg s "$RAILWAY_SERVICE_ID" '{input:{environmentId:$e,serviceId:$s,applicationPort:8080}}')
for NAME in tcpProxyCreate TCPProxyCreate tcpProxyAdd; do
  echo "trying $NAME"
  QUERY="mutation(\$input:TCPProxyCreateInput!){ $NAME(input:\$input){ id domain proxyPort applicationPort serviceId environmentId syncStatus } }"
  curl -sS https://backboard.railway.com/graphql/v2 \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    --data "$(jq -nc --arg q "$QUERY" --argjson v "$VARS" '{query:$q,variables:$v}')" | jq .
  echo
 done
