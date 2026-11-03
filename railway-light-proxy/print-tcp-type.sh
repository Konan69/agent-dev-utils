#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: print-tcp-type.sh; reads /tmp/railway-types.json (run types-tcp.sh first)'
  exit 0
fi
jq -r '.data.__schema.types[] | select(.name=="TCPProxyCreateInput" or .name=="TCPProxy") | .name as $n | "TYPE \($n)", ((.inputFields // .fields)[]? | "  \(.name)  \(.type.kind):\(.type.name // .type.ofType.name // .type.ofType.ofType.name)")' /tmp/railway-types.json
jq -r '.data.__schema.mutationType.fields[] | select((.args|tostring)|test("TCPProxy|tcpProxy|proxy")) | [.name, (.args|map(.name+":"+(.type.name // .type.ofType.name // "?"))|join(","))] | @tsv' /tmp/railway-types.json
