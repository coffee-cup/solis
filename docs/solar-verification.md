# Solar verification

Verified on 2026-09-26. The app and widget share the same Swift calculator, event model, calendar-day intervals, and bounded cache. Runtime calculation uses system frameworks only.

| Check | Result |
| --- | --- |
| Independent matrix | 14,760 intervals, 140,279 crossings, no mismatched counts, directions, dates or continuous states |
| Maximum reference difference | 31.46 seconds, below the 60-second requirement |
| Reference adjudication | 425 sensitive intervals checked against Skyfield/JPL DE440s; original fixtures retained |
| Raw USNO importer | Duplicate rows, polar states, incomplete responses tested |
| App-hosted tests | Solar invariants, date-line/DST days, polar states, photographic crossings, offline storage, stale enrichment, notifications, widget data and timeline switching |
| Release build | App and widget build; coefficient licence bundled in both targets |
| Simulator | Ordinary and polar timelines, scrolling, real event labels and continuous-state label inspected |
| Performance | About 3.3 ms for four uncached days; 33 ms for 40,000 cached day lookups in an optimised local Mac build |

Run `scripts/verify-solar.sh` for the complete independent matrix and `xcodebuild test` with the shared `SunriseSunset` scheme and an explicit simulator destination for integration tests. Fixture tests and the calculator do not access the network. Reference refresh tooling is development-only and records source hashes.

The review caught and corrected single-event days being described as polar night, stale permission/geocoder results overriding newer choices, photographic bands rendering behind the background, and structured records depending on separately written legacy coordinate keys. Regression tests cover the applicable event, storage and rendering contracts.

Current GPS locations use the phone's time zone. Fixed places retain a named time zone. A legacy offset remains usable offline and is marked unresolved until an online lookup supplies its zone. The app can save and calculate from a GPS fix before geocoding succeeds. Searching for a new city and enriching place names still use system online services.

A home-screen widget visual check on a physical device remains manual because the simulator tooling cannot add the widget headlessly. Widget data, target membership, extension structure and app-group entitlements were checked. Background refresh timing and actual notification delivery are controlled by iOS; the scheduler maintains one pending request per enabled alert kind and removes stale requests when there is no event in its four-day window.

The numerical contract uses a level sea-level horizon and conventional fixed refraction allowance. Weather, terrain and observer height can change observed sunrise or sunset. See [reference provenance and conventions](solar-reference.md) for the independent sources and their disagreements.
