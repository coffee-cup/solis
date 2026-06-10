#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/ios-loop-common.sh
source "$SCRIPT_DIR/ios-loop-common.sh"

usage() {
  cat <<'USAGE'
Usage: scripts/ios-loop-logs.sh [--last DURATION] [--predicate PREDICATE] [--output PATH] [--udid UDID]

Captures recent simulator logs to an artifact file.
Default predicate targets the Solis app and widget processes.
USAGE
}

last="2m"
predicate='process == "SunriseSunset" OR process == "SolisWidget" OR eventMessage CONTAINS[c] "jakerunzer.solis"'
output=""

while [ $# -gt 0 ]; do
  case "$1" in
    --last)
      last="${2:?missing duration}"
      shift 2
      ;;
    --predicate)
      predicate="${2:?missing predicate}"
      shift 2
      ;;
    --output)
      output="${2:?missing output path}"
      shift 2
      ;;
    --udid)
      IOS_LOOP_UDID="${2:?missing udid}"
      export IOS_LOOP_UDID
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
  output="$(ios_loop_artifact_path logs log solis)"
else
  mkdir -p "$(dirname "$output")"
fi

set +e
xcrun simctl spawn "$udid" log show --style compact --last "$last" --predicate "$predicate" >"$output" 2>&1
status=$?
set -e

printf '%s\n' "$output"
if [ "$status" -ne 0 ]; then
  echo "log show exited with $status; see $output" >&2
  exit "$status"
fi
