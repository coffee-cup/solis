//
//  LocationProvider.swift
//  SunriseSunset
//
//  App-target only: the widget compiles SunLocation.swift for the shared
//  app-group accessors but must not pull in CLLocationManager wiring.
//

import CoreLocation
import Foundation

// CLLocationManager wrapper providing permission requests, significant-change
// watching, and one-shot location fixes. The manager is created on the main
// thread, so delegate callbacks arrive there too.
@MainActor
class LocationProvider: NSObject, @preconcurrency CLLocationManagerDelegate {

    static let shared = LocationProvider()

    // Set by LocationModel; receives every fresh fix.
    var onLocationFix: ((CLLocationCoordinate2D) -> Void)?

    private let manager = CLLocationManager()
    private var watching = false
    private var permissionCompletions: [(Bool) -> Void] = []

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isAuthorized: Bool {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }

    func requestPermission(_ completion: @escaping (Bool) -> Void) {
        if manager.authorizationStatus == .notDetermined {
            permissionCompletions.append(completion)
            manager.requestWhenInUseAuthorization()
        } else {
            completion(isAuthorized)
        }
    }

    func startWatching() {
        watching = true
        if isAuthorized {
            manager.startMonitoringSignificantLocationChanges()
            manager.requestLocation()
        }
    }

    func requestOneShot() {
        if isAuthorized {
            manager.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }

        let completions = permissionCompletions
        permissionCompletions = []
        completions.forEach { $0(isAuthorized) }

        if watching {
            startWatching()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationFix?(location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// Location mutation and lookup. Reads stay in SunLocation.swift so the widget
// can share them.
@MainActor
extension SunLocation {

    class func startLocationWatching() {
        LocationProvider.shared.startWatching()
    }

    class func checkLocation() {
        LocationProvider.shared.requestOneShot()
    }

    class func isLocationAuthorized() -> Bool {
        return LocationProvider.shared.isAuthorized
    }

    class func requestLocationPermission(_ completion: @escaping (Bool) -> Void) {
        LocationProvider.shared.requestPermission(completion)
    }

    class func lookupLocation(_ coordinate: CLLocationCoordinate2D, completion: @escaping @MainActor @Sendable (_ placemark: CLPlacemark?) -> ()) {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            if let err = error {
                print("Error Reverse Geocoding Location: \(err.localizedDescription)")
            }
            let placemark = error == nil ? placemarks?.first : nil
            Task { @MainActor in
                completion(placemark)
            }
        })
    }

    class func setLocation(_ current: Bool, location: CLLocationCoordinate2D, name: String, sunplace: SunPlace? = nil) {
        defaults.set(name, forKey: DefaultKey.locationName.description)
        defaults.set(location.latitude, forKey: DefaultKey.locationLatitude.description)
        defaults.set(location.longitude, forKey: DefaultKey.locationLongitude.description)
        defaults.set(current, forKey: DefaultKey.currentLocation.description)

        if !current {
            defaults.set(sunplace?.placeID, forKey: DefaultKey.locationPlaceID.description)
        }
    }

    class func selectLocation(_ current: Bool, location: CLLocationCoordinate2D?, name: String?, sunplace: SunPlace?) {
        if current {
            if let currentLocation = getCurrentLocation() {
                if let locationName = getCurrentLocationName() {
                    setLocation(true, location: currentLocation, name: locationName)
                }
            }
            checkLocation()
        } else {
            if let sunplace = sunplace {
                setLocation(false, location: location!, name: name!, sunplace: sunplace)
                addLocationToHistory(sunplace)
                if let timeZoneOffset = sunplace.timeZoneOffset {
                    print("setting timezone offset from saved \(timeZoneOffset)")
                    Defaults.defaults.set(timeZoneOffset, forKey: DefaultKey.locationTimeZoneOffset.description)
                }
            }
        }
    }

    class func updateLocationHistoryWithTimeZone(_ location: CLLocationCoordinate2D, placeID: String, timeZoneOffset: Int) {
        if let locationHistory = getLocationHistory() {
            let index = locationHistory.firstIndex { place in
                return place.placeID == placeID
            }
            if let index = index {
                if index >= 0 && index < locationHistory.count {
                    let sunplace = locationHistory[index]
                    sunplace.timeZoneOffset = timeZoneOffset
                    print("saving timezoneoffset to history \(timeZoneOffset)")
                    addLocationToHistory(sunplace)
                }
            }
        }
    }

    // Reverse-geocodes the fix to a city name, persists it as the current
    // location, and calls completion after the save lands (or fails).
    class func saveLocation(_ location: CLLocationCoordinate2D, completion: (@MainActor @Sendable () -> Void)? = nil) {
        let now = Date()

        lookupLocation(location) { placemark in
            if let placemark = placemark, let city = placemark.locality {
                defaults.set(location.latitude, forKey: DefaultKey.currentLocationLatitude.description)
                defaults.set(location.longitude, forKey: DefaultKey.currentLocationLongitude.description)
                defaults.set(city, forKey: DefaultKey.currentLocationName.description)
                if isCurrentLocation() {
                    setLocation(true, location: location, name: city)
                    defaults.set(now, forKey: DefaultKey.locationDateSet.description)
                }
            }
            completion?()
        }
    }
}
