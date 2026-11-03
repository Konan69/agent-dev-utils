#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: schema-tcp.sh; introspects TCP-related GraphQL mutations'
  exit 0
fi
TOKEN=${RAILWAY_TOKEN:-$(jq -r '.user.accessToken // .user.token // empty' ~/.railway/config.json)}
QUERY='query { __schema { mutationType { fields { name args { name type { kind name ofType { kind name ofType { kind name } } } } } } } }'
curl -sS https://backboard.railway.com/graphql/v2 \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  --data "$(jq -nc --arg q "$QUERY" '{query:$q,variables:{}}')" \
  | tee /tmp/railway-schema.json \
  | jq -r '.data.__schema.mutationType.fields[] | select(.name|test("tcp|proxy|domain";"i")) | [.name, (.args|map(.name)|join(","))] | @tsv'
