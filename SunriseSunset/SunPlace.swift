import Foundation
import CoreLocation

class SunPlace: Equatable {
    var location: CLLocationCoordinate2D?
    var placeID: String
    var timeZoneOffset: Int?
    var timeZoneIdentifier: String?
    var primary: String
    var secondary: String
    var isNotification = false

    var stored: StoredPlace? {
        guard let location else { return nil }
        let value = StoredPlace(name: primary, detail: secondary, latitude: location.latitude, longitude: location.longitude,
                                id: placeID, timeZoneIdentifier: timeZoneIdentifier, fallbackOffset: timeZoneOffset, isNotification: isNotification)
        return value.isValid ? value : nil
    }
    var needsTimeZone: Bool { timeZoneIdentifier == nil }
    var toString: String? { stored?.encoded }

    static func sunPlaceFromString(_ string: String) -> SunPlace? {
        guard let value = StoredPlace.decode(string) else { return nil }
        let place = SunPlace(primary: value.name, secondary: value.detail,
                             location: CLLocationCoordinate2D(latitude: value.latitude, longitude: value.longitude),
                             placeID: value.id, timeZoneOffset: value.fallbackOffset, isNotification: value.isNotification)
        place.timeZoneIdentifier = value.timeZoneIdentifier
        return place
    }

    init(primary: String, secondary: String, placeID: String) {
        self.primary = primary; self.secondary = secondary; self.placeID = placeID
    }

    init(primary: String, secondary: String, location: CLLocationCoordinate2D, placeID: String, timeZoneOffset: Int?, isNotification: Bool) {
        self.primary = primary; self.secondary = secondary; self.location = location
        self.placeID = placeID; self.timeZoneOffset = timeZoneOffset; self.isNotification = isNotification
    }

    static func == (lhs: SunPlace, rhs: SunPlace) -> Bool { lhs.placeID == rhs.placeID }
}
