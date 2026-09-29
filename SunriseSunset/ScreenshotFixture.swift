import Foundation

enum ScreenshotFixture {
    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--app-store-screenshots")
        #else
        false
        #endif
    }

    static var now: Date {
        #if DEBUG
        if isEnabled {
            // September 17, 2026 at 6:50 pm in Vancouver.
            return Date(timeIntervalSince1970: 1789696200)
        }
        #endif
        return Date()
    }

    static func prepare() {
        #if DEBUG
        guard isEnabled else { return }
        // Volatile overrides disappear at exit and never alter the app-group plist.
        var values = Defaults.defaults.volatileDomain(forName: UserDefaults.argumentDomain)
        values.merge([
            "CurrentLocation": false,
            "LocationName": "Vancouver",
            "LocationLatitude": 49.2827,
            "LocationLongitude": -123.1207,
            "LocationPlaceID": "49.2827,-123.1207",
            "LocationTimeZoneOffset": -25_200,
            "CurrentLocationName": "Vancouver",
            "TimeFormat": "h:mm a",
            "Theme": ProcessInfo.processInfo.arguments.contains("--screenshot-ember") ? "ember" : "classic",
            "ShowSunAreas": true,
            "Sunrise": true,
            "Sunset": true,
            "FirstLight": false,
            "LastLight": false,
            "NotificationPlace": "",
            "LocationHistoryPlaces": [
                "Vancouver|Canada|49.2827|-123.1207|49.2827,-123.1207|-25200|false",
                "Reykjavík|Iceland|64.1466|-21.9426|64.1466,-21.9426|0|false",
                "Tokyo|Japan|35.6762|139.6503|35.6762,139.6503|32400|false",
                "Lisbon|Portugal|38.7223|-9.1393|38.7223,-9.1393|3600|false",
            ],
        ]) { _, fixture in fixture }
        Defaults.defaults.setVolatileDomain(values, forName: UserDefaults.argumentDomain)
        #endif
    }
}
