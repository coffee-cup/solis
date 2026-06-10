# Solis — Agent Guide

iOS app showing sunrise/sunset/twilight times on a scrollable day timeline. UIKit + storyboards (2016-era, being modernized), Swift 5 mode, zero external dependencies, iOS 16+, built with Xcode 26.

## Layout

```text
SunriseSunset.xcodeproj        the whole project (no workspace, no CocoaPods — never add/recreate either)
SunriseSunset/                 app target source
  SunViewController.swift      main timeline UI (scroll/zoom, sun lines)
  SunLogic.swift, Sun.swift    sun-time calculations (wraps EDSunriseSet)
  EDSunriseSet/                vendored ObjC sunrise/sunset lib (via bridging header)
  SunLocation.swift            CoreLocation wrapper (LocationProvider) + saved-location accessors
  TimeZones.swift              timezone via CLGeocoder reverse geocoding
  LocationChangeViewController.swift   city search via MKLocalSearchCompleter/MKLocalSearch
  Notifications.swift          local notifications (still on legacy UILocalNotification)
  Defaults.swift               UserDefaults(suiteName: "group.SunriseSunset") + DefaultKey enum
  Bus.swift                    NotificationCenter wrapper for app events
  Spring/                      vendored animation lib
SolisWidget/                   WidgetKit extension (SwiftUI), shares app sources + EDSunriseSet
scripts/ios-loop-*.sh          simulator loop helpers (see below)
```

## Build / run / test

```bash
scripts/ios-loop-sim.sh --connect-iosef --shutdown-older   # pin ONE simulator (critical)
scripts/ios-loop-build.sh                                  # build app + widget, install on sim
scripts/ios-loop-prepare.sh --grant-location --location 49.2827,-123.1207
scripts/ios-loop-launch.sh
scripts/ios-loop-screenshot.sh --name check
```

Raw build: `xcodebuild -project SunriseSunset.xcodeproj -scheme SunriseSunset -destination "platform=iOS Simulator,id=<UDID>" build`

For anything interactive (taps, assertions, screenshots, logs, seeding app state, verifying UI changes), use the **ios-simulator-loop skill** (`.claude/skills/ios-simulator-loop/SKILL.md`). It documents the app's screens, accessibility quirks, defaults keys, and known simulator failure modes. There is no unit-test suite worth running yet (`SunriseSunsetTests` is an empty template).

## Hard-won gotchas

- **Never use the `booted` simctl alias or build with `CODE_SIGNING_ALLOWED=NO`.** Multiple booted sims resolve nondeterministically; unsigned bundles silently break `simctl privacy` grants and app-group entitlements.
- App state lives in the **app group** `group.SunriseSunset`. Seed/read it via the group container plist (prepare script), not `defaults write`. Reads can lag cfprefsd by a few seconds.
- `MKAddressFilter(including: .locality)` on `MKLocalSearchCompleter` returns zero results (iOS 26 sim) — the completer intentionally uses plain `.address` results. Don't "improve" it back.
- **pbxproj edits**: use the `xcodeproj` Ruby gem bundled with Homebrew CocoaPods:
  `GEM_HOME=/opt/homebrew/Cellar/cocoapods/<ver>/libexec /opt/homebrew/opt/ruby/bin/ruby script.rb`
  When removing build files, collect them first and remove after iterating — mutating `phase.files` while iterating corrupts the gem's referrer tracking (save fails atomically, so the project file survives).
- The widget can't be added to the home screen headlessly; verify the `.appex` structure/entitlements instead (see skill) and ask the human for visual checks.
- `print()` from the app does not appear in `log show`; use `simctl launch --console-pty` (backgrounded) to capture it.

## Modernization state

- Done: CocoaPods fully removed (dead SDKs replaced with system APIs), iOS 16 floor, WidgetKit widget replacing the old Today extension.
- Backlog (phase 3): `UILocalNotification` → `UNUserNotificationCenter`, `setMinimumBackgroundFetchInterval` → `BGAppRefreshTask`, async/await + Swift 6 mode, replace `Bus` with typed notifications, accessibility labels on main-screen buttons, privacy manifest before any App Store release.
- Old Google Places/timezonedb API keys exist in git history; they are dead/revoked — do not reuse that pattern; the app needs no API keys.
