//
//  Location.swift
//  SunriseSunset
//
//  Shared app-group location storage, compiled into both the app and the
//  widget. Mutation and CLLocationManager wiring live in LocationProvider.swift
//  (app target only).
//

import CoreLocation
import Foundation

class SunLocation {

    // See Defaults.defaults: UserDefaults is thread-safe, not Sendable.
    nonisolated(unsafe) static let defaults = Defaults.defaults

    static let CHECK_THRESHOLD = 60 * 10; // seconds

    // Timezone of the displayed location: device-local for the current
    // location, otherwise the stored offset of the selected place.
    static var currentTimeZone: TimeZone {
        if isCurrentLocation() {
            return TimeZone.ReferenceType.local
        }
        if let timeZone = getTimeZone() {
            return timeZone
        }
        return TimeZone.ReferenceType.local
    }

    class func getTimeZone() -> TimeZone? {
        let gmtOffset = Defaults.defaults.integer(forKey: DefaultKey.locationTimeZoneOffset.description)
        return TimeZone(secondsFromGMT: gmtOffset)
    }

    class func getCurrentLocation() -> CLLocationCoordinate2D? {
        let latitude = defaults.double(forKey: DefaultKey.currentLocationLatitude.description)
        let longitude = defaults.double(forKey: DefaultKey.currentLocationLongitude.description)

        if latitude == 0 || longitude == 0 {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    class func getLocation() -> CLLocationCoordinate2D? {
        let latitude = defaults.double(forKey: DefaultKey.locationLatitude.description)
        let longitude = defaults.double(forKey: DefaultKey.locationLongitude.description)

        if latitude == 0 || longitude == 0 {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    class func getNotificationLocation() -> CLLocationCoordinate2D? {
        if let sunPlaceString = defaults.object(forKey: DefaultKey.notificationPlace.description) as? String {
            let sunPlace = SunPlace.sunPlaceFromString(sunPlaceString)
            if let sunPlace = sunPlace {
                if let location = sunPlace.location {
                    print("notification for \(sunPlace.primary)")
                    return location
                }
            }
        }
        print("notification for current location")
        return getCurrentLocation()
    }

    class func getPlaceID() -> String? {
        return defaults.string(forKey: DefaultKey.locationPlaceID.description)
    }

    class func getLocationName() -> String? {
        return defaults.string(forKey: DefaultKey.locationName.description)
    }

    class func getCurrentLocationName() -> String? {
        return defaults.string(forKey: DefaultKey.currentLocationName.description)
    }

    class func isCurrentLocation() -> Bool {
        return defaults.bool(forKey: DefaultKey.currentLocation.description)
    }

    class func getLocationHistory() -> [SunPlace]? {
        if let locationHistoryPlaces = defaults.object(forKey: DefaultKey.locationHistoryPlaces.description) as? [String] {
            var places: [SunPlace] = []
            for placeString in locationHistoryPlaces {
                if let sunplace = SunPlace.sunPlaceFromString(placeString) {
                    places.append(sunplace)
                }
            }
            return places
        }
        return nil
    }

    class func saveLocationHistory(_ places: [SunPlace]) {
        var sunPlaceString = defaults.object(forKey: DefaultKey.notificationPlace.description) as? String
        sunPlaceString = sunPlaceString == nil ? "" : sunPlaceString
        var notificationSunPlace: SunPlace? = nil
        if let sunPlaceString = sunPlaceString {
            notificationSunPlace = SunPlace.sunPlaceFromString(sunPlaceString)
        }

        let placeStrings: [String] = places.map { place in
            if let notificationSunPlace = notificationSunPlace {
                if notificationSunPlace.placeID == place.placeID {
                    place.isNotification = true
                } else {
                    place.isNotification = false
                }
            } else {
                place.isNotification = false
            }
            if let placeString = place.toString {
                return placeString
            }
            return ""
        }
        defaults.set(placeStrings, forKey: DefaultKey.locationHistoryPlaces.description)
    }

    class func addLocationToHistory(_ sunplace: SunPlace) {
        if var locationHistory: [SunPlace] = getLocationHistory() {
            if let index = locationHistory.firstIndex(of: sunplace) {
                locationHistory.remove(at: index)
            }

            locationHistory.insert(sunplace, at: 0)

            if locationHistory.count > 5 {
                locationHistory = Array(locationHistory[0...4])
            }

            saveLocationHistory(locationHistory)
        }
    }

    // Returns if we need to update the location
    class func needCheck() -> Bool {
        if defaults.double(forKey: DefaultKey.locationLatitude.description) == 0 ||
            defaults.double(forKey: DefaultKey.locationLongitude.description) == 0 {
            return true
        }

        guard let date = defaults.object(forKey: DefaultKey.locationDateSet.description) else {
            return false
        }

        guard let differenceSeconds = (date as AnyObject).timeIntervalSinceNow else {
            return false
        }

        return (Int(differenceSeconds)) > CHECK_THRESHOLD
    }
}
