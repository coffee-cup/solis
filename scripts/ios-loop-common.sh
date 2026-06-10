#!/usr/bin/env bash

set -euo pipefail

IOS_LOOP_DEFAULT_DEVICE="${IOS_LOOP_DEVICE:-iPhone 17 Pro}"
IOS_LOOP_DEFAULT_BUNDLE_ID="${IOS_LOOP_BUNDLE_ID:-xyz.jakerunzer.solis}"
IOS_LOOP_ARTIFACT_DIR="${IOS_LOOP_ARTIFACT_DIR:-.ios-loop}"
IOS_LOOP_BOOT_SETTLE_SECONDS="${IOS_LOOP_BOOT_SETTLE_SECONDS:-5}"
IOS_LOOP_PROJECT="SunriseSunset.xcodeproj"
IOS_LOOP_SCHEME="SunriseSunset"
IOS_LOOP_APP_GROUP="group.SunriseSunset"

if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

ios_loop_timestamp() {
  date +"%Y%m%d-%H%M%S"
}

ios_loop_require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

ios_loop_artifact_path() {
  local kind="$1"
  local ext="$2"
  local label="${3:-$kind}"
  mkdir -p "$IOS_LOOP_ARTIFACT_DIR/$kind"
  printf '%s/%s/%s-%s.%s\n' "$IOS_LOOP_ARTIFACT_DIR" "$kind" "$(ios_loop_timestamp)" "$label" "$ext"
}

ios_loop_select_udid() {
  local state_filter="${1:-}"
  local device_name="${2:-$IOS_LOOP_DEFAULT_DEVICE}"

  xcrun simctl list devices available -j 2>/dev/null | python3 -c '
import json
import re
import sys

state_filter = sys.argv[1]
device_name = sys.argv[2]
data = json.load(sys.stdin)

def runtime_version(runtime):
    match = re.search(r"iOS-(\d+(?:-\d+)*)", runtime)
    if not match:
        return ()
    return tuple(int(part) for part in match.group(1).split("-"))

def device_score(device):
    name = device.get("name", "")
    exact = 1 if name == device_name else 0
    fallback = 1 if "iPhone" in name and "Pro" in name and "Max" not in name else 0
    return (exact, fallback)

candidates = []
for runtime, devices in data.get("devices", {}).items():
    version = runtime_version(runtime)
    for device in devices:
        if not device.get("isAvailable", True):
            continue
        if state_filter and device.get("state") != state_filter:
            continue
        score = device_score(device)
        if score == (0, 0):
            continue
        candidates.append((version, score, device.get("udid", "")))

if candidates:
    candidates.sort(reverse=True)
    print(candidates[0][2])
' "$state_filter" "$device_name"
}

ios_loop_booted_udid() {
  ios_loop_select_udid Booted "$IOS_LOOP_DEFAULT_DEVICE"
}

ios_loop_available_udid() {
  ios_loop_select_udid "" "${1:-$IOS_LOOP_DEFAULT_DEVICE}"
}

ios_loop_is_booted() {
  local udid="$1"
  xcrun simctl list devices booted 2>/dev/null | grep -Fq "$udid"
}

ios_loop_ensure_booted() {
  ios_loop_require xcrun

  local udid="${IOS_LOOP_UDID:-}"
  local booted_now="false"
  if [ -z "$udid" ]; then
    udid=$(ios_loop_booted_udid || true)
  fi

  if [ -z "$udid" ]; then
    udid=$(ios_loop_available_udid "$IOS_LOOP_DEFAULT_DEVICE" || true)
  fi

  if [ -z "$udid" ]; then
    echo "No available iPhone simulator found." >&2
    exit 1
  fi

  if ! ios_loop_is_booted "$udid"; then
    echo "Booting latest $IOS_LOOP_DEFAULT_DEVICE ($udid)" >&2
    xcrun simctl boot "$udid" >/dev/null || true
    booted_now="true"
  fi

  xcrun simctl bootstatus "$udid" -b >/dev/null
  if [ "$booted_now" = "true" ] && [ "$IOS_LOOP_BOOT_SETTLE_SECONDS" != "0" ]; then
    sleep "$IOS_LOOP_BOOT_SETTLE_SECONDS"
  fi
  printf '%s\n' "$udid"
}

ios_loop_installed_app_path() {
  local udid="$1"
  local bundle_id="$2"
  xcrun simctl get_app_container "$udid" "$bundle_id" app 2>/dev/null || true
}

# Preferences plist inside the app-group container. The app reads/writes all
# state through UserDefaults(suiteName: group.SunriseSunset); seeding state
# must target this file, NOT `simctl spawn ... defaults write group.SunriseSunset`
# (that writes to a different domain the signed app never reads).
ios_loop_group_plist() {
  local udid="$1"
  local container
  container="$(xcrun simctl get_app_container "$udid" "$IOS_LOOP_DEFAULT_BUNDLE_ID" groups 2>/dev/null | awk -v g="$IOS_LOOP_APP_GROUP" '$1 == g {print $2}')"
  if [ -z "$container" ]; then
    echo "app group container not found; is the app installed?" >&2
    return 1
  fi
  mkdir -p "$container/Library/Preferences"
  printf '%s/Library/Preferences/%s.plist\n' "$container" "$IOS_LOOP_APP_GROUP"
}
