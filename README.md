# Solis

[![CI](https://github.com/coffee-cup/solis/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/coffee-cup/solis/actions/workflows/ci.yml)

![app icon](http://i.imgur.com/wezWMEi.png)

A simple iOS app to show you when the sun sets, rises, and in between.

```
            ^^                   @@@@@@@@@
       ^^       ^^            @@@@@@@@@@@@@@@
                            @@@@@@@@@@@@@@@@@@              ^^
                           @@@@@@@@@@@@@@@@@@@@
 ~~~~ ~~ ~~~~~ ~~~~~~~~ ~~ &&&&&&&&&&&&&&&&&&&& ~~~~~~~ ~~~~~~~~~~~ ~~~
 ~         ~~   ~  ~       ~~~~~~~~~~~~~~~~~~~~ ~       ~~     ~~ ~
   ~      ~~      ~~ ~~ ~~  ~~~~~~~~~~~~~ ~~~~  ~     ~~~    ~ ~~~  ~ ~~
   ~  ~~     ~         ~      ~~~~~~  ~~ ~~~       ~~ ~ ~~  ~~ ~
 ~  ~       ~ ~      ~           ~~ ~~~~~~  ~      ~~  ~             ~~
       ~             ~        ~      ~      ~~   ~             ~ 
```


![phones](http://i.imgur.com/QHkGXon.png)


## Development

1. Clone repo
2. Open `SunriseSunset.xcodeproj`

No external dependencies. Requires Xcode 26+, targets iOS 18+.

## App Store screenshots

Run `python3 scripts/app-store-screenshots.py` to capture the app and generate
1320 × 2868 artwork, a contact sheet, and an upload ZIP. See
[the screenshot guide](media/app-store/README.md) for requirements and Media Manager steps.

## Solar calculations

Sunrise, sunset, twilight, and photographic bands are calculated locally in Swift.
GPS coordinates are saved before optional geocoding; saved places retain named
time zones for offline DST handling. Current GPS locations use the phone's time zone.
Legacy places keep their stored offset until an online lookup resolves a named zone.

Run `scripts/verify-solar.sh` for the independent reference matrix, then the shared
Xcode scheme's tests for app, widget, storage, and notification behaviour. See
[the calculation contract and reference provenance](docs/solar-reference.md).
