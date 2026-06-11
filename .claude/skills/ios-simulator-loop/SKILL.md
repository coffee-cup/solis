---
name: ios-simulator-loop
description: Close the iOS Simulator feedback loop for Solis. Use when an agent needs to build/install/launch the app, boot/inspect/control the simulator, capture screenshots/logs, seed app state (location), validate UI changes, run selector-based interactions, or produce before/after evidence.
version: 1.0.0
license: MIT
---

# iOS Simulator Loop (Solis)

Use this skill to observe, act, and verify in the iOS Simulator for this repo. Solis is a plain native app (no Metro/Expo/dev server) — agents may build, install, and launch freely.

## Hard rules

- **Pin one simulator first**: `scripts/ios-loop-sim.sh --connect-iosef --shutdown-older`. Multiple booted sims make `xcrun simctl ... booted` and bare `iosef connect` resolve to different devices and everything gets flaky. Always pass explicit UDIDs after that.
- **Never build with `CODE_SIGNING_ALLOWED=NO`**. Unsigned bundles break `simctl privacy` grants and app-group entitlements. Default sim signing needs no team/account.
- **Seed app state only via the app-group plist** (`scripts/ios-loop-prepare.sh` does this). `xcrun simctl spawn <udid> defaults write group.SunriseSunset ...` writes to a domain the app never reads.
- Reads of the group plist can lag (cfprefsd flushes lazily). If an assertion on saved state fails right after a UI action, wait a few seconds and re-read before concluding it's broken.
- `print()` output from the app is invisible to `log show`. To capture it, launch with `--console` (backgrounded) — see Observe.
- Prefer semantic/selector checks over pixel-perfect image diffs. Keep evidence: screenshot/log paths, commands run, pass/fail assertion.

Repo facts:

```text
project: SunriseSunset.xcodeproj (no workspace — never recreate one)
scheme: SunriseSunset (builds app + SolisWidget extension)
app bundle: xyz.jakerunzer.solis
widget bundle: xyz.jakerunzer.solis.SolisWidget
app group: group.SunriseSunset
artifacts: .ios-loop/ (gitignored)
iosef session: .iosef/ (gitignored)
```

## One-time tooling

`iosef` gives selector-based taps, assertions, screenshots, and logs. If it is missing, ask the user before installing it; install approval is per machine/user, not project-wide.

```bash
python3 -m venv ~/.local/share/iosef-venv
~/.local/share/iosef-venv/bin/python -m pip install --upgrade pip iosef
mkdir -p ~/.local/bin && ln -sf ~/.local/share/iosef-venv/bin/iosef ~/.local/bin/iosef
export PATH="$HOME/.local/bin:$PATH"
```

Without iosef, use the screenshot/log scripts and visual inspection; system permission dialogs then require `simctl privacy` (flaky, see Failure modes).

## Helper scripts

Run from the repo root.

```bash
scripts/ios-loop-env.sh                                  # tool/sim/app status
scripts/ios-loop-sim.sh --connect-iosef --shutdown-older # pin latest sim, close others
scripts/ios-loop-build.sh                                # xcodebuild + simctl install (app + widget)
scripts/ios-loop-prepare.sh --grant-location --location 49.2827,-123.1207
scripts/ios-loop-launch.sh                               # launch (terminates running instance)
scripts/ios-loop-screenshot.sh --name base               # capture PNG into .ios-loop/screenshots
scripts/ios-loop-logs.sh --last 2m                       # app/widget logs into .ios-loop/logs
```

Env overrides: `IOS_LOOP_DEVICE` (default "iPhone 17 Pro"), `IOS_LOOP_UDID`, `IOS_LOOP_BUNDLE_ID`, `IOS_LOOP_ARTIFACT_DIR`.

## Core loop

1. Define the expected outcome in one sentence.
2. `scripts/ios-loop-env.sh`
3. `scripts/ios-loop-sim.sh --connect-iosef --shutdown-older`
4. `scripts/ios-loop-build.sh`
5. `scripts/ios-loop-prepare.sh --reset --grant-location --location 49.2827,-123.1207` (pick flags for the scenario; set `--location` again before every launch that needs a fix)
6. `scripts/ios-loop-launch.sh` and capture baseline screenshot + logs.
7. If the location permission dialog appears anyway, dismiss it by selector:
   ```bash
   iosef tap --name "Allow While Using App"
   ```
8. Inspect structure before guessing coordinates: `iosef describe --depth 3`
9. Act with selectors first (`iosef tap/type/wait/exists`); main-screen buttons are labeled (`settings`, `center on now`). Watch for substring matches — `--name "Allow"` can hit "Don't Allow" on system alerts; describe first and tap exact coordinates on permission dialogs.
10. Make the smallest code change, rebuild (`scripts/ios-loop-build.sh`), relaunch.
11. Capture after evidence and compare semantically.

## App map

Main screen (sun timeline):
- Scrollable day view; "now" line with current time; sun-event lines (sunrise/sunset/first light/last light) appear at their time positions — events can be off-screen at default zoom, so an empty-looking colored screen is normal during midday/midnight.
- Background colour reflects the current sun period (teal/cyan = day, blues/purples = twilight/night) and is itself evidence the EDSunriseSet calculations ran.
- Bottom-left AXButton `settings` opens the settings sheet; bottom-right `center on now` appears after panning and recenters the timeline.
- The app is SwiftUI (UIKit only for the timeline view controller, hosted in a representable). The timeline pans from any x position, including the left edge.

Settings sheet (after tapping bottom-left `settings`) — NavigationStack + Form, all selector-accessible:
- location row (AXButton labeled `<City>` or `<City>, Current Location`) → pushes location search
- `Theme, <Name>` row → pushes the theme picker (`Classic` / `Ember` / `Midnight` / `Aurora` rows; tap recolours the timeline live behind the sheet)
- `Time Format, <value>` AXPopUpButton → menu with `12-hour` / `24-hour` / `Relative (±)`
- `Sunrise` / `Sunset` / `First Light` / `Last Light` AXCheckBox toggles (these trigger the notification permission prompt; a denial snaps the toggle back off)
- `About Solis` → pushes the gradient about page (`Day`/`Civil`/`Nautical`/`Astronomical`/`Night` buttons push detail pages with standard back chevrons)
- `Done` closes the sheet (only on the root settings page; pushed pages show back chevrons)

Location search (pushed page):
- `.searchable` nav-bar search field — NOT exposed as a named AXTextField; tap it by coordinates (~x 200, y 155 in the sheet) then `iosef type --text "<city>"`.
- Results come from `MKLocalSearchCompleter` async — `iosef wait --name "<City>, <Country>" --timeout 10` then tap the row.
- Row 0 is "Current Location"; bell buttons (`notifications on`/`notifications off`) set the notification place.
- Result rows expose one combined label, `"<Primary>, <Secondary>"` (e.g. `Tokyo, Japan`). The completer list reshuffles asynchronously while typing — a tap right after `wait` can land on a different row whose subtitle contains the same text; `describe` and tap exact coordinates when row identity matters.
- Selecting a result resolves coordinates via `MKLocalSearch`, pops back to settings, then saves location + fetches timezone via `CLGeocoder` — verify via group plist keys below.

Group defaults keys (app-group plist): `CurrentLocation` (bool: using current location), `CurrentLocationLatitude/Longitude/Name`, `LocationLatitude/Longitude`, `LocationName`, `LocationPlaceID` ("lat,lng" string), `LocationTimeZoneOffset` (seconds from GMT), `TimeFormat`, `Theme` (`classic`/`ember`/`midnight`/`aurora`), `Sunrise`/`Sunset`/`FirstLight`/`LastLight` (notification toggles), `LocationHistoryPlaces`.

Read state:

```bash
UDID="$(scripts/ios-loop-sim.sh --print-udid)"
GC="$(xcrun simctl get_app_container "$UDID" xyz.jakerunzer.solis groups | awk '{print $2}')"
plutil -p "$GC/Library/Preferences/group.SunriseSunset.plist"
```

## Observe

```bash
scripts/ios-loop-screenshot.sh --name logged-out
iosef describe --depth 3          # accessibility tree; frames are center±halfsize
iosef find --role AXButton
iosef exists --name "Close"
iosef wait --name "Tokyo, Japan" --timeout 10
scripts/ios-loop-logs.sh --last 2m
```

App `print()` output (bounded, background it — `--console` blocks):

```bash
UDID="$(scripts/ios-loop-sim.sh --print-udid)"
nohup xcrun simctl launch --console-pty --terminate-running-process "$UDID" xyz.jakerunzer.solis > /tmp/solis-console.log 2>&1 &
# interact, then read /tmp/solis-console.log
```

## Act

```bash
iosef tap --name "Vancouver"
iosef tap --name "settings"                   # bottom-left settings button
iosef tap --x 200 --y 155 && iosef type --text "Tokyo"   # nav-bar search field
xcrun simctl ui "$UDID" appearance dark        # restore after validating
xcrun simctl location "$UDID" set 49.2827,-123.1207
xcrun simctl privacy "$UDID" grant location xyz.jakerunzer.solis
xcrun simctl privacy "$UDID" reset all xyz.jakerunzer.solis
```

Use `wait`/`exists` instead of fixed sleeps where possible; MapKit/geocoder calls need a few seconds.

## Widget (SolisWidget)

WidgetKit extension built/embedded by the same scheme. There is no headless way to add a widget to the home screen — do not claim widget UI was verified visually. Verify instead:

```bash
APP=.ios-loop/DerivedData/Build/Products/Debug-iphonesimulator/SunriseSunset.app
plutil -p "$APP/PlugIns/SolisWidget.appex/Info.plist" | grep -E "ExtensionPointIdentifier|BundleIdentifier"
strings "$APP/PlugIns/SolisWidget.appex/SolisWidget" | grep -A2 application-groups
```

Timeline logic lives in `SolisWidget/SolisWidget.swift` and reuses `SunLogic`, which the app exercises. Ask the human for a manual widget-gallery check when it matters.

## Common scenarios

### Fresh-install smoke

```bash
scripts/ios-loop-sim.sh --connect-iosef --shutdown-older
scripts/ios-loop-build.sh
scripts/ios-loop-prepare.sh --reset --grant-location --location 49.2827,-123.1207
scripts/ios-loop-launch.sh
sleep 5
iosef exists --name "now"      # main screen rendered
scripts/ios-loop-screenshot.sh --name smoke
```

Then assert the group plist has `CurrentLocationName => Vancouver` (location pipeline: fix → reverse geocode → save).

### Change location flow

```bash
iosef tap --name "settings"              # open settings sheet
iosef tap --name "Vancouver"             # location row (label = current city)
iosef tap --x 200 --y 155                # .searchable nav-bar field (no AX name)
iosef type --text "Tokyo"
iosef wait --name "Tokyo, Japan" --timeout 10
iosef tap --name "Tokyo, Japan"          # combined row label; see completer-reshuffle caveat
sleep 6                                  # MKLocalSearch + CLGeocoder timezone fetch
```

Assert plist: `LocationName => Tokyo`, `LocationTimeZoneOffset => 32400`, `CurrentLocation => false`.

### Before/after report

```text
Expectation: ...
Before screenshot: .ios-loop/screenshots/...
After screenshot: .ios-loop/screenshots/...
Logs: .ios-loop/logs/...
Assertions: iosef wait/exists ... passed|failed
Remaining issues: ...
```

## Failure modes

- **`simctl privacy grant location` doesn't stick** (stale locationd state, wrong UDID, prior unsigned install): launch anyway and `iosef tap --name "Allow While Using App"`. A full `simctl uninstall` + reinstall + grant-before-first-launch also resets it.
- **Two booted simulators**: the cause of most "worked then didn't" mysteries. Re-run `scripts/ios-loop-sim.sh --shutdown-older`.
- **App state assertion fails right after acting**: cfprefsd lag — re-read the plist after a few seconds before debugging the app.
- **Empty search results while typing**: completer callbacks are async and can deliver a stale list before the final one; `iosef wait` on the expected row instead of asserting immediately.
- **Selector missing**: most legacy controls lack accessibility labels; use `iosef describe` coordinates. Adding labels is a welcome small improvement when touching a screen.
- **No location fix after relaunch** (no `CurrentLocationName` saved, no sun lines): `simctl location set` does not always survive app relaunches — re-run `scripts/ios-loop-prepare.sh --location ...` immediately before the launch that needs it.
- **Stale app state after `--reset`**: should not happen (the script restarts cfprefsd), but if values look like the pre-reset state, terminate the app, restart cfprefsd (`xcrun simctl spawn "$UDID" launchctl kickstart -k system/com.apple.cfprefsd.xpc.daemon`), and relaunch.
- **App not installed**: run `scripts/ios-loop-build.sh`; do not pretend validation passed.
