import CoreLocation
import Foundation

/// Shared app-group reads and storage. No geocoder or CLLocationManager dependency.
class SunLocation {
    nonisolated(unsafe) static let defaults = Defaults.defaults
    static let CHECK_THRESHOLD = 600

    static var currentTimeZone: TimeZone {
        isCurrentLocation() ? .current : getTimeZone() ?? .gmt
    }
    static func getTimeZone() -> TimeZone? { StoredPlace.saved(in: defaults, current: false)?.timeZone }
    static func getCurrentLocation() -> CLLocationCoordinate2D? { coordinate(StoredPlace.saved(in: defaults, current: true)) }
    static func getLocation() -> CLLocationCoordinate2D? {
        coordinate(StoredPlace.saved(in: defaults, current: isCurrentLocation()))
    }
    private static func coordinate(_ place: StoredPlace?) -> CLLocationCoordinate2D? {
        place.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
    static var notificationPlace: StoredPlace? {
        defaults.string(forKey: "NotificationPlace").flatMap(StoredPlace.decode)
    }
    static func getNotificationLocation() -> CLLocationCoordinate2D? { coordinate(notificationPlace) ?? getCurrentLocation() }
    static var notificationTimeZone: TimeZone { notificationPlace?.timeZone ?? .current }
    static func getPlaceID() -> String? { defaults.string(forKey: "LocationPlaceID") }
    static func getLocationName() -> String? {
        isCurrentLocation() ? getCurrentLocationName() : StoredPlace.saved(in: defaults, current: false)?.name
    }
    static func getCurrentLocationName() -> String? { StoredPlace.saved(in: defaults, current: true)?.name }
    static func isCurrentLocation() -> Bool { defaults.object(forKey: "CurrentLocation") as? Bool ?? true }

    static func getLocationHistory() -> [SunPlace]? {
        (defaults.array(forKey: "LocationHistoryPlaces") as? [String])?.compactMap(SunPlace.sunPlaceFromString)
    }
    static func saveLocationHistory(_ places: [SunPlace]) {
        let notificationID = notificationPlace?.id
        defaults.set(places.prefix(5).compactMap { place in
            place.isNotification = place.placeID == notificationID
            return place.toString
        }, forKey: "LocationHistoryPlaces")
    }
    static func addLocationToHistory(_ place: SunPlace) {
        var history = getLocationHistory() ?? []
        history.removeAll { $0.placeID == place.placeID }
        history.insert(place, at: 0)
        saveLocationHistory(history)
    }
    static func needCheck() -> Bool {
        guard getCurrentLocation() != nil, let date = defaults.object(forKey: "LocationDateSet") as? Date else { return true }
        return Date().timeIntervalSince(date) > Double(CHECK_THRESHOLD)
    }
    static func migrateStorage() {
        for current in [true, false] {
            if let place = StoredPlace.saved(in: defaults, current: current), let encoded = place.encoded {
                defaults.set(encoded, forKey: current ? "CurrentPlaceV1" : "SelectedPlaceV1")
            }
        }
        if let history = getLocationHistory() { saveLocationHistory(history) }
        if let place = notificationPlace { defaults.set(place.encoded, forKey: "NotificationPlace") }
    }
}
