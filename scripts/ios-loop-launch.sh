#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/ios-loop-common.sh
source "$SCRIPT_DIR/ios-loop-common.sh"

usage() {
  cat <<'USAGE'
Usage: scripts/ios-loop-launch.sh [--bundle BUNDLE_ID] [--udid UDID] [--console]

Launches Solis on a booted simulator, booting the default simulator if needed.
If the app is not installed, run scripts/ios-loop-build.sh first.
USAGE
}

bundle_id="$IOS_LOOP_DEFAULT_BUNDLE_ID"
console="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --bundle)
      bundle_id="${2:?missing bundle id}"
      shift 2
      ;;
    --udid)
      IOS_LOOP_UDID="${2:?missing udid}"
      export IOS_LOOP_UDID
      shift 2
      ;;
    --console)
      console="true"
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
app_path="$(ios_loop_installed_app_path "$udid" "$bundle_id")"
if [ -z "$app_path" ]; then
  echo "App is not installed on simulator $udid: $bundle_id" >&2
  echo "Run scripts/ios-loop-build.sh to build and install it." >&2
  exit 1
fi

if [ "$console" = "true" ]; then
  xcrun simctl launch --console-pty --terminate-running-process "$udid" "$bundle_id"
else
  xcrun simctl launch --terminate-running-process "$udid" "$bundle_id" >/dev/null
  printf 'launched %s on %s\n' "$bundle_id" "$udid"
fi
