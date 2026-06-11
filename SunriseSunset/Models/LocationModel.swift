//
//  LocationModel.swift
//  SunriseSunset
//

import CoreLocation
import Foundation
import Observation

// Single app-side owner of location state. Persistence stays in the shared
// SunLocation accessors (the widget reads the same app-group keys); this model
// orchestrates mutations and exposes change tokens that drive the timeline.
@MainActor
@Observable
final class LocationModel {

    private(set) var locationName: String?
    private(set) var isCurrentLocation = true

    // Bumped on any location or timezone data change; the timeline recomputes.
    private(set) var updateToken = 0

    // Bumped when the user picks a different place; the timeline scroll-resets.
    private(set) var changeToken = 0

    func start() {
        LocationProvider.shared.onLocationFix = { [weak self] coordinate in
            SunLocation.saveLocation(coordinate) {
                self?.refresh()
            }
        }
        SunLocation.requestLocationPermission { granted in
            if granted {
                SunLocation.startLocationWatching()
            }
        }
        refresh()
    }

    func refresh() {
        locationName = SunLocation.getLocationName()
        isCurrentLocation = SunLocation.isCurrentLocation()
        updateToken += 1
    }

    func selectCurrentLocation() {
        SunLocation.requestLocationPermission { [weak self] granted in
            guard granted else { return }
            SunLocation.startLocationWatching()
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.changeToken += 1
                SunLocation.selectLocation(true, location: nil, name: nil, sunplace: nil)
                self.refresh()
            }
        }
    }

    func select(_ place: SunPlace, coordinate: CLLocationCoordinate2D) {
        changeToken += 1
        SunLocation.selectLocation(false, location: coordinate, name: place.primary, sunplace: place)
        refresh()
        Task {
            await fetchTimeZone(for: coordinate)
        }
    }

    // Replaces the fetchTimeZone/gotTimeZone bus round-trip: resolve the
    // selected place's timezone, persist the offset, and refresh.
    private func fetchTimeZone(for coordinate: CLLocationCoordinate2D) async {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location),
              let timeZone = placemarks.first?.timeZone else {
            print("Reverse geocode returned no time zone")
            return
        }

        let gmtOffset = timeZone.secondsFromGMT(for: Date())
        Defaults.defaults.set(gmtOffset, forKey: DefaultKey.locationTimeZoneOffset.description)

        if !SunLocation.isCurrentLocation(), let placeID = SunLocation.getPlaceID() {
            SunLocation.updateLocationHistoryWithTimeZone(coordinate, placeID: placeID, timeZoneOffset: gmtOffset)
        }

        refresh()
    }
}
