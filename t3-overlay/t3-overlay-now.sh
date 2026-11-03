#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == --help ]]; then
  echo 'Usage: t3-overlay-now.sh <bundle-checkout> <windows-resources-dir> <linux-cli-archive>'
  echo 'Or set T3_BUNDLE_DIR, T3_RESOURCES_DIR, and T3_CLI_ARCHIVE. Requires WSL and the bundle installer.'
  exit 0
fi
B=${1:-${T3_BUNDLE_DIR:?set T3_BUNDLE_DIR or pass bundle checkout}}
R=${2:-${T3_RESOURCES_DIR:?set T3_RESOURCES_DIR or pass resources directory}}
CLI=${3:-${T3_CLI_ARCHIVE:?set T3_CLI_ARCHIVE or pass CLI archive}}
IMG='T3 Code (Nightly).exe'
log(){ printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
for t in tasklist.exe cmd.exe node; do command -v "$t" >/dev/null || { log "$t not on PATH"; exit 1; }; done
n(){ tasklist.exe /FI "IMAGENAME eq $IMG" /FO CSV /NH | tr -d '\r' | grep -cF "\"$IMG\"" || true; }
log "waiting for T3 Code to exit (quit it fully, tray too)"
w=0; while [ "$(n)" -gt 0 ]; do [ $w -ge 86400 ] && { log "T3 still running after 24h; nothing changed"; exit 1; }; sleep 5; w=$((w+5)); done
log "T3 exited; applying overlay"
node "$B/scripts/install-local-windows-bundle.cjs" "$B" "$R" "$CLI"
for m in 'pi --mode rpc' MachineService; do grep -aqF "$m" "$R/server.asar" || { log "marker missing: $m"; exit 1; }; done
log "overlay verified; relaunching"
cmd.exe /c start "" "$(wslpath -w "$R/../T3 Code (Nightly).exe")"
log done
