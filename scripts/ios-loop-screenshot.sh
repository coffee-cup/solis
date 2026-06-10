#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/ios-loop-common.sh
source "$SCRIPT_DIR/ios-loop-common.sh"

usage() {
  cat <<'USAGE'
Usage: scripts/ios-loop-screenshot.sh [--name LABEL] [--udid UDID] [--output PATH]

Captures a simulator screenshot. Boots the default simulator if none is booted.
USAGE
}

label="screen"
output=""

while [ $# -gt 0 ]; do
  case "$1" in
    --name)
      label="${2:?missing label}"
      shift 2
      ;;
    --udid)
      IOS_LOOP_UDID="${2:?missing udid}"
      export IOS_LOOP_UDID
      shift 2
      ;;
    --output)
      output="${2:?missing output path}"
      shift 2
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
if [ -z "$output" ]; then
  output="$(ios_loop_artifact_path screenshots png "$label")"
else
  mkdir -p "$(dirname "$output")"
fi

xcrun simctl io "$udid" screenshot "$output" >/dev/null
printf '%s\n' "$output"
