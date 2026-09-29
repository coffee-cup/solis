#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -m unittest discover -s scripts/solar-reference -p 'test_*.py'
solar_temp="$(mktemp -d "${TMPDIR:-/tmp}/solis-solar.XXXXXX")"
trap 'rm -rf "$solar_temp"' EXIT
xcrun swiftc -O -swift-version 6 -module-cache-path "$solar_temp/modules" \
  SunriseSunset/SolarCoefficients.swift SunriseSunset/SolarPosition.swift \
  SunriseSunset/SolarCalculator.swift scripts/solar-reference/verify.swift \
  -o "$solar_temp/verify"
"$solar_temp/verify" SunriseSunsetTests/Fixtures/Solar
