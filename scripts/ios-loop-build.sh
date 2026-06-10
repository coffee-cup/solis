#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/ios-loop-common.sh
source "$SCRIPT_DIR/ios-loop-common.sh"

usage() {
  cat <<'USAGE'
Usage: scripts/ios-loop-build.sh [--udid UDID] [--no-install] [--clean]

Builds the SunriseSunset scheme (app + widget) for the simulator and installs
the app on it. Uses default simulator code signing so entitlements (app group)
are embedded -- do not pass CODE_SIGNING_ALLOWED=NO; simctl privacy grants
silently fail against unsigned bundles.
USAGE
}

install="true"
clean=""

while [ $# -gt 0 ]; do
  case "$1" in
    --udid)
      IOS_LOOP_UDID="${2:?missing udid}"
      export IOS_LOOP_UDID
      shift 2
      ;;
    --no-install)
      install="false"
      shift
      ;;
    --clean)
      clean="clean"
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

ios_loop_require xcodebuild

udid="$(ios_loop_ensure_booted)"
derived_data="$IOS_LOOP_ARTIFACT_DIR/DerivedData"
log_path="$(ios_loop_artifact_path logs log xcodebuild)"

set +e
# shellcheck disable=SC2086
xcodebuild \
  -project "$IOS_LOOP_PROJECT" \
  -scheme "$IOS_LOOP_SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$udid" \
  -derivedDataPath "$derived_data" \
  $clean build >"$log_path" 2>&1
status=$?
set -e

if [ "$status" -ne 0 ]; then
  echo "build failed; errors:" >&2
  grep -E "error:" "$log_path" | sort -u | head -20 >&2
  echo "full log: $log_path" >&2
  exit "$status"
fi

app_path="$derived_data/Build/Products/Debug-iphonesimulator/SunriseSunset.app"
printf 'built %s\n' "$app_path"

if [ "$install" = "true" ]; then
  xcrun simctl install "$udid" "$app_path"
  printf 'installed %s on %s\n' "$IOS_LOOP_DEFAULT_BUNDLE_ID" "$udid"
fi
