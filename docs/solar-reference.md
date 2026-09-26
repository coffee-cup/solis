# Solar calculation contract and independent baseline

The reference data was generated and frozen on 2026-09-26, before replacing any production calculation. `SunriseSunsetTests/Fixtures/Solar/manifest.json` records the frozen hashes. Fixture refresh is a deliberate development task, never a test or app network request.

The contract is the apparent, topocentric solar centre at sea level, without applying atmospheric refraction to the computed altitude. Fixed thresholds are -50/60 degrees for sunrise/set, -6/-12/-18 for twilight, and -4/+6 for photographic bands. The sunrise threshold already includes the conventional mean solar radius and refraction allowance. There is no terrain or weather model. UTC approximates UT1; historical and future delta-T use the documented NASA polynomial approximation. Supported civil years are 1801 through 2099.

Events belong to the half-open absolute interval for the location's civil date. Directions and event counts must agree exactly. Time tolerance against the precise reference is 60 seconds. A day can have no events, one event, or multiple events of the same kind. Continuous above/below states are separate from event timestamps. Day lengths follow the named time zone, including DST and date-line changes.

## Sources

- [US Naval Observatory tables](https://aa.usno.navy.mil/data/RS_OneYear) supply 80 raw yearly tables, covering 20 locations and four thresholds throughout 2026. Each request URL and response hash is recorded in `sources.json`. The importer preserves duplicate rows and absent-event markers. Coordinates printed by the tables have arcminute precision; the cross-check uses those displayed coordinates.
- [Astronomy Engine](https://github.com/cosinekitty/astronomy) supplies independent positions for 14,760 intervals. The vendored development tool has its MIT notice and a pinned content hash. It uses a different position implementation from the Swift SPA solver. The generator brackets altitude crossings, explicitly searches extrema, and saves full-precision results for all six thresholds. The app and tests do not execute this JavaScript.
- The Swift position model follows [NREL SPA, report 34302](https://docs.nlr.gov/docs/fy08osti/34302.pdf). Coefficient transcription is attributed separately. It is not the fixture generator.

## Reference disagreement policy

`reference-disagreements.json` preserves the 49 event-field discrepancies after aligning the USNO table coordinates. Most are minute rounding across midnight, including days with two same-direction events. Fourteen remaining fields are near polar transitions. USNO does not publish the implementation of this table service. Those residuals are retained as secondary-source disagreements rather than used to widen the solver tolerance.

Sensitive cases are adjudicated with Skyfield 1.54 and the JPL DE440s ephemeris. The selection is independent of production output: all USNO disagreements, all polar crossings, all crossings within 60 seconds of midnight, and neighbouring civil days. `adjudicated.json` contains 425 intervals; `adjudication-source.json` records the ephemeris hash, versions, and conventions. `adjudicate.py` reproduces them using a separately downloaded development-only ephemeris. These additions were made while investigating the initial port comparison; the original frozen Astronomy Engine fixtures remain unchanged.

Both the solver and adjudicator approximate UT1 with the input UTC timestamp. Using Skyfield's historical UTC conversion instead would introduce a different time-scale convention, especially before UTC existed. The adjudicator therefore constructs UT1 times explicitly. This distinction also matters for a crossing within a fraction of a second of midnight. The higher-precision JPL fixtures replace Astronomy Engine expectations only for the independently selected cases. All event counts, directions, civil-date ownership, and continuous states agree exactly after adjudication. No time tolerances were relaxed.

The complete offline comparison covers 14,760 intervals and 140,279 crossings. The worst time difference is 31.46 seconds, within the 60-second requirement. Astronomy Engine is adequate for most events but its advertised angular accuracy is not sufficient to settle every grazing or polar crossing. Physical observations can still vary with the atmosphere and terrain.

USNO's [definitions and accuracy discussion](https://aa.usno.navy.mil/faq/RST_defs) explain the fixed-altitude conventions and the sensitivity of real observed times near the poles. That physical uncertainty does not excuse numerical error against the chosen mathematical model.

## Unchanged Objective-C baseline

`legacy-baseline.json` records the result of running the actual unchanged EDSunriseSet source through a Foundation command-line probe against the full fixture input matrix. Its source hash is included. `python3 scripts/solar-reference/baseline.py` reconstructs the pinned legacy source from git and reproduces the report against the final, adjudicated inputs. The desired civil-interval contract differs from the legacy solar-cycle pair contract, so outside-day and count statistics include that semantic mismatch. Known regressions include synthetic polar-night events, shifted date-line dates, grazing twilight errors, fixed-offset DST drift, and angle interpolation for photographic bands. Existing green unit tests did not establish astronomical accuracy.

## Offline reproduction

Run `python3 scripts/solar-reference/import_usno.py` to re-import the saved HTML and `node scripts/solar-reference/generate_astronomy.cjs` to regenerate the independent ephemeris fixtures. `--fetch` on the importer is the only operation requiring the USNO network service. Review all changes before running `freeze.py`. Production code must never be used to regenerate expected results.

## Verification commands

`./scripts/verify-solar.sh` compiles the same Foundation-only Swift source with optimisation and checks every frozen reference, including provenance hashes. On the development Mac the comparison itself takes about 8 seconds. CI runs it before the simulator unit tests. App-hosted tests additionally cover all adjudicated cases, a distributed fixture sample, random-coordinate invariants, storage, widget calculations, and notification planning. No verification command fetches reference data.
