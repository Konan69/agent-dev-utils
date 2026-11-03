#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: mutations.sh; introspects GraphQL mutations using RAILWAY_TOKEN or CLI login'
  exit 0
fi
TOKEN=${RAILWAY_TOKEN:-$(jq -r '.user.accessToken // .user.token // empty' ~/.railway/config.json)}
QUERY='query { __schema { mutationType { fields { name args { name type { kind name ofType { kind name ofType { kind name } } } } type { kind name ofType { kind name } } } } } }'
curl -sS https://backboard.railway.com/graphql/v2 \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  --data "$(jq -nc --arg q "$QUERY" '{query:$q,variables:{}}')" \
  > /tmp/railway-mutations.json
jq -r '.data.__schema.mutationType.fields[] | select(.name|test("create|tcp|proxy";"i")) | [.name, (.args|map(.name+":"+(.type.name // .type.ofType.name // .type.ofType.ofType.name // "?"))|join(",")), (.type.name // .type.ofType.name // "?")] | @tsv' /tmp/railway-mutations.json
