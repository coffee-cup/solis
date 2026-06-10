#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/ios-loop-common.sh
source "$SCRIPT_DIR/ios-loop-common.sh"

check_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf 'ok      %s %s\n' "$name" "$(command -v "$name")"
  else
    printf 'missing %s\n' "$name"
  fi
}

printf 'Solis iOS loop\n'
printf 'cwd: %s\n' "$(pwd -P)"
printf 'project: %s %s\n' "$IOS_LOOP_PROJECT" "$([ -d "$IOS_LOOP_PROJECT" ] && echo ok || echo missing)"
printf 'scheme: %s\n' "$IOS_LOOP_SCHEME"
printf 'bundle: %s\n' "$IOS_LOOP_DEFAULT_BUNDLE_ID"
printf 'app group: %s\n' "$IOS_LOOP_APP_GROUP"
printf 'artifact dir: %s\n' "$IOS_LOOP_ARTIFACT_DIR"
printf '\nTools\n'
for tool in xcrun xcodebuild iosef python3 plutil; do
  check_command "$tool"
done

printf '\nSimulator\n'
booted_udid="$(ios_loop_booted_udid || true)"
if [ -n "$booted_udid" ]; then
  printf 'booted: %s\n' "$booted_udid"
else
  printf 'booted: none\n'
  printf 'candidate: %s\n' "$(ios_loop_available_udid "$IOS_LOOP_DEFAULT_DEVICE" || echo none)"
fi

if [ -n "$booted_udid" ]; then
  app_path="$(ios_loop_installed_app_path "$booted_udid" "$IOS_LOOP_DEFAULT_BUNDLE_ID")"
  if [ -n "$app_path" ]; then
    printf 'installed app: yes (%s)\n' "$app_path"
  else
    printf 'installed app: no (%s)\n' "$IOS_LOOP_DEFAULT_BUNDLE_ID"
  fi
fi

printf '\niosef\n'
if [ -f .iosef/state.json ]; then
  printf 'local state: '
  python3 - <<'PY' 2>/dev/null || cat .iosef/state.json
import json
print(json.load(open('.iosef/state.json')).get('device', 'unknown'))
PY
fi
if command -v iosef >/dev/null 2>&1; then
  iosef status 2>/dev/null || true
else
  printf 'not installed\n'
fi

printf '\nNext\n'
printf '%s\n' '- choose latest sim: scripts/ios-loop-sim.sh --connect-iosef --shutdown-older'
printf '%s\n' '- build + install: scripts/ios-loop-build.sh'
printf '%s\n' '- prep state: scripts/ios-loop-prepare.sh --skip-walkthrough --grant-location --location 49.2827,-123.1207'
printf '%s\n' '- launch: scripts/ios-loop-launch.sh'
printf '%s\n' '- screenshot: scripts/ios-loop-screenshot.sh --name baseline'
printf '%s\n' '- logs: scripts/ios-loop-logs.sh --last 2m'
printf '%s\n' '- selector tools: iosef describe && iosef tap --name "skip"'
