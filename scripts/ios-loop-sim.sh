#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/ios-loop-common.sh
source "$SCRIPT_DIR/ios-loop-common.sh"

usage() {
  cat <<'USAGE'
Usage: scripts/ios-loop-sim.sh [--print-udid] [--connect-iosef] [--shutdown-older]

Selects the latest available simulator matching IOS_LOOP_DEVICE (default iPhone 17 Pro),
boots it if needed, and optionally points the local iosef session at it.
USAGE
}

print_udid=false
connect_iosef=false
shutdown_older=false

while [ $# -gt 0 ]; do
  case "$1" in
    --print-udid)
      print_udid=true
      shift
      ;;
    --connect-iosef)
      connect_iosef=true
      shift
      ;;
    --shutdown-older)
      shutdown_older=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

udid="$(ios_loop_ensure_booted)"

if [ "$shutdown_older" = true ]; then
  while read -r other; do
    if [ -n "$other" ] && [ "$other" != "$udid" ]; then
      xcrun simctl shutdown "$other" >/dev/null || true
      echo "shutdown older booted simulator $other" >&2
    fi
  done < <(xcrun simctl list devices booted 2>/dev/null | grep -Eo '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')
fi

if [ "$connect_iosef" = true ]; then
  if ! command -v iosef >/dev/null 2>&1; then
    echo "iosef is not installed" >&2
    exit 1
  fi
  mkdir -p .iosef
  printf '{\n  "device": "%s"\n}\n' "$udid" > .iosef/state.json
  echo "iosef local session pinned to $udid" >&2
fi

if [ "$print_udid" = true ] || { [ "$connect_iosef" = false ] && [ "$shutdown_older" = false ]; }; then
  printf '%s\n' "$udid"
fi
