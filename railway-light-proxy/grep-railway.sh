#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' 'Usage: grep-railway.sh; searches RAILWAY_REFERENCE_DIR and /tmp/railway-*.json'
  exit 0
fi
grep -R -E 'environment.*patch|service.*config|TCPProxyCreateInput|tcpProxy' -n "${RAILWAY_REFERENCE_DIR:?Set RAILWAY_REFERENCE_DIR to Railway reference files}" /tmp/railway-*.json 2>/dev/null | head -120
