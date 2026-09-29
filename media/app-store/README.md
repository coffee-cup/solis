# App Store screenshots

Generate the current iPhone screenshots with the same capture-and-render workflow
used in [Bowtie](https://github.com/coffee-cup/bowtie2/commit/a0c0e9c).
Requires Xcode 26.5 with the iOS 26.5 simulator runtime, Python 3, and macOS.
No pip, npm, or app dependencies are added.

```sh
python3 scripts/app-store-screenshots.py
```

The command builds the `SolisScreenshots` scheme, creates a temporary iPhone 17 Pro
Max simulator, pins that simulator through `ios-loop-sim.sh`, and shuts down other
booted simulators. It runs UI tests against real app screens, exports their PNG
attachments, then renders the artwork with AppKit. The temporary simulator is
deleted on completion or failure. Existing simulator data is not erased.
Builds retain normal simulator signing so the app-group entitlement works.

The four screens show the timeline, themes, saved locations, and alert settings.
Screenshots use English Canada, a fixed Vancouver evening, and a
fixed list of saved places. Theme and Location use the half-height sheet. Alert
settings show Sunrise and Sunset enabled. The debug-only fixture uses volatile defaults and
skips location requests and notification scheduling. Normal launches use the real
date and saved settings. Release builds cannot enable the fixture.

## Outputs

- `raw/en-CA/iphone-6.9/`: original simulator captures.
- `upload/en-CA/iphone-6.9/`: four opaque RGB PNGs to upload, in filename order.
- `upload/en-CA/iphone-6.9-contact-sheet.png`: overview for review, not upload.
- `index.html`: local gallery with full-size links.
- `solis-app-store-screenshots.zip`: only the upload PNGs.
- `build/app-store/run-*/`: ignored build logs, test results, configuration, and run metadata.

Review every image before uploading. The old Today widget screenshot is not reused.
The current WidgetKit widget would need a separate real capture before inclusion.

## Change the artwork

Edit headlines and background colours in `config.json`, then re-render without
running the simulator:

```sh
python3 scripts/app-store-screenshots.py --render-only
```

Layout and the vector phone frame live in `scripts/render-app-store.swift`.
Screen navigation and capture assertions live in
`SunriseSunsetUITests/AppStoreScreenshotTests.swift`. Fixture values live in
`SunriseSunset/ScreenshotFixture.swift`, which belongs only to the app target.
After changing app or test code, run the full command. `--skip-build` is only for
retrying captures against an unchanged previous build.

The screenshot scheme is separate from the normal unit-test scheme, so screenshot
generation does not run on every CI build. The capture suite also checks that a
normal launch on the fresh simulator does not retain the fixture location.

## Sizes and Media Manager

Checked September 17, 2026 against Apple's
[screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
and [upload instructions](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots).

Solis targets iPhone only. One 6.9-inch set at **1320 × 2868** covers the iPhone
requirement. Apple also accepts 1260 × 2736 and 1290 × 2796 in this slot and scales
the largest required screenshots to smaller displays when no custom set exists.
A separate 13-inch set is required if iPad support is added later.

1. Open the editable iOS version in App Store Connect and select English Canada.
2. Open **View All Sizes in Media Manager** and expand **6.9-inch Display**.
3. Upload the four PNGs inside `upload/en-CA/iphone-6.9/`, in numeric order.
4. Remove the obsolete custom 5.5-inch screenshots and inspect every other size
   for stale custom assets. Use the inherited larger-size set for smaller sizes.
5. Check every supported localization for old overrides, then save and review
   the resulting previews. Matching English localizations can use these images;
   translated captions need their own artwork.

Apple accepts 1–10 screenshots per set. PNGs must have no alpha channel. The
generator validates dimensions and opaque 8-bit RGB output before packaging.
It does not upload to App Store Connect or submit an app version.
