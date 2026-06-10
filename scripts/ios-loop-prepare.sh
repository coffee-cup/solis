#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/ios-loop-common.sh
source "$SCRIPT_DIR/ios-loop-common.sh"

usage() {
  cat <<'USAGE'
Usage: scripts/ios-loop-prepare.sh [--udid UDID] [options]

Prepares Solis app state on the simulator. The app must already be installed
(scripts/ios-loop-build.sh). Run before launching; the app reads this state
at startup.

Options:
  --skip-walkthrough        skip the first-run walkthrough
  --show-walkthrough        re-enable the first-run walkthrough
  --grant-location          grant location permission (avoids the system prompt)
  --revoke-location         reset location permission to not-determined
  --location LAT,LNG        set the simulated device location
  --reset                   wipe all saved app state (group defaults)

Defaults state lives in the app-group container plist; keys of interest:
ShowWalkthrough, CurrentLocationLatitude/Longitude, CurrentLocationName,
LocationName, TimeFormat, Sunrise/Sunset/FirstLight/LastLight (notifications).
USAGE
}

skip_walkthrough="false"
show_walkthrough="false"
grant_location="false"
revoke_location="false"
location=""
reset="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-walkthrough) skip_walkthrough="true"; shift ;;
    --show-walkthrough) show_walkthrough="true"; shift ;;
    --grant-location) grant_location="true"; shift ;;
    --revoke-location) revoke_location="true"; shift ;;
    --location) location="${2:?missing lat,lng}"; shift 2 ;;
    --reset) reset="true"; shift ;;
    --udid)
      IOS_LOOP_UDID="${2:?missing udid}"
      export IOS_LOOP_UDID
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

udid="$(ios_loop_ensure_booted)"

if [ -z "$(ios_loop_installed_app_path "$udid" "$IOS_LOOP_DEFAULT_BUNDLE_ID")" ]; then
  echo "App is not installed on $udid; run scripts/ios-loop-build.sh first." >&2
  exit 1
fi

set_bool() {
  local plist="$1" key="$2" value="$3"
  /usr/libexec/PlistBuddy -c "Add :$key bool $value" "$plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist"
}

if [ "$reset" = "true" ]; then
  # cfprefsd caches the group domain; deleting the plist alone leaves the app
  # reading stale values. Terminate the app and restart cfprefsd too.
  xcrun simctl terminate "$udid" "$IOS_LOOP_DEFAULT_BUNDLE_ID" 2>/dev/null || true
  plist="$(ios_loop_group_plist "$udid")"
  rm -f "$plist"
  xcrun simctl spawn "$udid" launchctl kickstart -k system/com.apple.cfprefsd.xpc.daemon 2>/dev/null || true
  sleep 1
  echo "cleared group defaults ($plist)"
fi

if [ "$skip_walkthrough" = "true" ]; then
  plist="$(ios_loop_group_plist "$udid")"
  [ -f "$plist" ] || plutil -create binary1 "$plist"
  set_bool "$plist" ShowWalkthrough false
  echo "walkthrough disabled"
fi

if [ "$show_walkthrough" = "true" ]; then
  plist="$(ios_loop_group_plist "$udid")"
  [ -f "$plist" ] || plutil -create binary1 "$plist"
  set_bool "$plist" ShowWalkthrough true
  echo "walkthrough enabled"
fi

if [ "$grant_location" = "true" ]; then
  xcrun simctl privacy "$udid" grant location "$IOS_LOOP_DEFAULT_BUNDLE_ID"
  echo "location permission granted"
fi

if [ "$revoke_location" = "true" ]; then
  xcrun simctl privacy "$udid" reset location "$IOS_LOOP_DEFAULT_BUNDLE_ID"
  echo "location permission reset"
fi

if [ -n "$location" ]; then
  # Does not always survive app relaunches; re-run before each launch that
  # needs a location fix.
  xcrun simctl location "$udid" set "$location"
  echo "device location set to $location"
fi
