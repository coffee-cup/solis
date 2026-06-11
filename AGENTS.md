# Solis — Agent Guide

iOS app showing sunrise/sunset/twilight times on a scrollable day timeline. SwiftUI app lifecycle with one wrapped UIKit view controller for the timeline, zero external dependencies, iOS 18+, built with Xcode 26.

## Layout

```text
SunriseSunset.xcodeproj        the whole project (no workspace, no CocoaPods — never add/recreate either)
SunriseSunset/                 app target source
  SolisApp.swift               @main SwiftUI App: registered defaults, BGTask registration, model wiring
  Views/                       RootView (timeline + gear → settings sheet), SettingsView (+ThemePickerView), LocationSearchView, InfoMenuView (AboutView), InfoView
  Models/                      @Observable models: LocationModel, SettingsModel, LocationSearchModel
  Timeline/TimelineView.swift  UIViewControllerRepresentable hosting SunViewController; token-diffed updates
  SunViewController.swift      UIKit timeline (programmatic layout; gesture scroll/momentum, gradient, sun lines)
  SunLogic.swift, Sun.swift    sun-time calculations (wraps EDSunriseSet)
  EDSunriseSet/                vendored ObjC sunrise/sunset lib (via bridging header)
  SunLocation.swift            shared app-group location storage (also compiled into the widget)
  LocationProvider.swift       app-only CLLocationManager wrapper + SunLocation mutation/geocoding extension
  Services/                    NotificationScheduler (UNUserNotificationCenter), BackgroundRefresh (BGAppRefreshTask)
  Defaults.swift               UserDefaults(suiteName: "group.SunriseSunset") + DefaultKey enum
  Styles.swift                 SunTheme/SunPalette (selectable timeline palettes) + theme-aware colour globals + fonts
SolisWidget/                   WidgetKit extension (SwiftUI), shares SunLogic/SunLocation/Defaults/EDSunriseSet
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

Unit tests (Swift Testing, app-hosted in `SunriseSunsetTests`; covers SunLogic/Date extensions/SunPlace):
`xcodebuild test -project SunriseSunset.xcodeproj -scheme SunriseSunset -destination "platform=iOS Simulator,id=<UDID>"`
The `SunriseSunset` scheme is shared (`xcshareddata/xcschemes`) so CI can run it — keep it committed. CI (`.github/workflows/ci.yml`) runs the same command on every push/PR. `SunriseSunsetUITests` is still an empty template and not in the scheme.

For anything interactive (taps, assertions, screenshots, logs, seeding app state, verifying UI changes), use the **ios-simulator-loop skill** (`.claude/skills/ios-simulator-loop/SKILL.md`). It documents the app's screens, accessibility quirks, defaults keys, and known simulator failure modes.

## Hard-won gotchas

- **Never use the `booted` simctl alias or build with `CODE_SIGNING_ALLOWED=NO`.** Multiple booted sims resolve nondeterministically; unsigned bundles silently break `simctl privacy` grants and app-group entitlements.
- App state lives in the **app group** `group.SunriseSunset`. Seed/read it via the group container plist (prepare script), not `defaults write`. Reads can lag cfprefsd by a few seconds.
- `MKAddressFilter(including: .locality)` on `MKLocalSearchCompleter` returns zero results (iOS 26 sim) — the completer intentionally uses plain `.address` results. Don't "improve" it back.
- **pbxproj edits**: use the `xcodeproj` Ruby gem bundled with Homebrew CocoaPods:
  `GEM_HOME=/opt/homebrew/Cellar/cocoapods/<ver>/libexec /opt/homebrew/opt/ruby/bin/ruby script.rb`
  When removing build files, collect them first and remove after iterating — mutating `phase.files` while iterating corrupts the gem's referrer tracking (save fails atomically, so the project file survives).
- The widget can't be added to the home screen headlessly; verify the `.appex` structure/entitlements instead (see skill) and ask the human for visual checks.
- `print()` from the app does not appear in `log show`; use `simctl launch --console-pty` (backgrounded) to capture it.
- SplashBoard caches the launch screen per bundle ID across reinstalls — after changing `UILaunchScreen`, reboot the sim to see it. To view the settled launch screen at all (the app paints over it in ~300ms), launch with `simctl launch --wait-for-debugger`, screenshot, then terminate.
- Notification permission state (incl. a previous denial) survives app uninstall/reinstall on the iOS 26 sim — the permission prompt will not reappear; the alert toggles then silently snap back off. There is no simctl domain for notifications; flip it in the sim's Settings app or erase the sim.
- `xcrun simctl ui <udid> appearance dark` can report `dark` while every app (including system Settings) keeps rendering light — reboot the sim (`simctl shutdown` + `boot`) and it applies.
- Mixing view-destination `NavigationLink { ... }` with value-based pushes in the same `NavigationStack` double-pushes on iOS 26 — keep all settings-stack navigation value-based (`SettingsRoute`, `InfoData` destinations registered on the stack root).

## Modernization state

- Done: CocoaPods fully removed (dead SDKs replaced with system APIs), WidgetKit widget, iOS 18 floor, SwiftUI app lifecycle (storyboards/walkthrough/Spring deleted), `UNUserNotificationCenter` + `BGAppRefreshTask`, Bus replaced by `@Observable` models, accessibility labels on main-screen buttons, Swift 6 language mode (default MainActor isolation on the app target; widget stays nonisolated), settings sheet replacing the slide-out menu (SF Symbols, system font, NavigationStack pushes; medium/large detents on a faded `.ultraThinMaterial` glass background, pushed lists use `containerBackground(.clear, for: .navigation)` to keep it), selectable timeline palettes (`SunTheme`: classic/ember/midnight/aurora/infrared, persisted in `Theme` group-defaults key; widget follows), light+dark mode (forced-light `UIUserInterfaceStyle`/`preferredColorScheme` removed). Timeline + widget keep the Muli brand font; all chrome uses the system font.
- Remaining backlog: privacy manifest before any App Store release.
- The widget compiles `SunLogic/SunLocation/Defaults/TimeFormatters/SunPlace/SunType/Suntime/NSDate/Styles/UIColor` directly — never add app-only files (Views/Models/Services/LocationProvider) to the widget target, and keep `SunLocation.swift` free of UIKit/CLLocationManager references.
- Old Google Places/timezonedb API keys exist in git history; they are dead/revoked — do not reuse that pattern; the app needs no API keys.
