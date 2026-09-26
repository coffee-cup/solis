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
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }
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

    class func selectLocation(_ current: Bool, location: CLLocationCoordinate2D?, name: String?, sunplace: SunPlace?) {
        defaults.set(current, forKey: "CurrentLocation")
        if current { checkLocation(); return }
        guard let place = sunplace, let location else { return }
        place.location = location
        guard let stored = place.stored else { return }
        defaults.set(stored.encoded, forKey: "SelectedPlaceV1")
        defaults.set(stored.latitude, forKey: "LocationLatitude")
        defaults.set(stored.longitude, forKey: "LocationLongitude")
        defaults.set(stored.name, forKey: "LocationName")
        defaults.set(stored.id, forKey: "LocationPlaceID")
        defaults.set(stored.fallbackOffset ?? stored.timeZone.secondsFromGMT(), forKey: "LocationTimeZoneOffset")
        addLocationToHistory(place)
    }

    /// Save before attempting optional online enrichment. The callback fires for
    /// the immediate fix and again if a current geocode adds a useful name.
    class func saveLocation(_ location: CLLocationCoordinate2D, completion: (@MainActor @Sendable () -> Void)? = nil) {
        guard let revision = StoredPlace.saveFix(latitude: location.latitude, longitude: location.longitude, at: Date(), in: defaults) else { return }
        completion?()
        lookupLocation(location) { placemark in
            guard let name = placemark?.locality ?? placemark?.administrativeArea ?? placemark?.name,
                  StoredPlace.enrichFix(name: name, revision: revision, in: defaults) else { return }
            completion?()
        }
    }
}
