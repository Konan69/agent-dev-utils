#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: types-tcp.sh; saves GraphQL type introspection to /tmp/railway-types.json'
  exit 0
fi
TOKEN=${RAILWAY_TOKEN:-$(jq -r '.user.accessToken // .user.token // empty' ~/.railway/config.json)}
QUERY='query { __schema { types { name kind inputFields { name type { kind name ofType { kind name ofType { kind name } } } } fields { name type { kind name ofType { kind name ofType { kind name } } } args { name type { kind name ofType { kind name } } } } } } }'
curl -sS https://backboard.railway.com/graphql/v2 \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  --data "$(jq -nc --arg q "$QUERY" '{query:$q,variables:{}}')" \
  > /tmp/railway-types.json
jq -r '.data.__schema.types[] | select(.name|test("Tcp|TCP|Proxy|Domain|ServiceDomain")) | .name' /tmp/railway-types.json
