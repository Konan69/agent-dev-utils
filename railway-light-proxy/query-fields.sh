#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: query-fields.sh; introspects GraphQL query fields using RAILWAY_TOKEN or CLI login'
  exit 0
fi
TOKEN=${RAILWAY_TOKEN:-$(jq -r '.user.accessToken // .user.token // empty' ~/.railway/config.json)}
QUERY='query { __schema { queryType { fields { name args { name type { kind name ofType { kind name ofType { kind name } } } } type { kind name ofType { kind name ofType { kind name } } } } } } }'
curl -sS https://backboard.railway.com/graphql/v2 \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  --data "$(jq -nc --arg q "$QUERY" '{query:$q,variables:{}}')" \
  | jq -r '.data.__schema.queryType.fields[] | select(.name|test("tcp|proxy|domain";"i")) | [.name, (.args|map(.name+":"+(.type.name // .type.ofType.name // .type.ofType.ofType.name // "?"))|join(",")), (.type.name // .type.ofType.name // .type.ofType.ofType.name // "?")] | @tsv'
