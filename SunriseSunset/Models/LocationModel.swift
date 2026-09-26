//
//  LocationModel.swift
//  SunriseSunset
//

import CoreLocation
import Foundation
import Observation
import WidgetKit

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
        SunLocation.migrateStorage()
        upgradeSelectedTimeZone()
        upgradeNotificationTimeZone()
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
        WidgetCenter.shared.reloadAllTimelines()
        Task { await NotificationScheduler.reschedule() }
    }

    func selectCurrentLocation() {
        changeToken += 1
        // A saved GPS fix stays usable even after permission has been revoked.
        SunLocation.selectLocation(true, location: nil, name: nil, sunplace: nil)
        refresh()
        SunLocation.requestLocationPermission { granted in
            if granted { SunLocation.startLocationWatching() }
        }
    }

    func select(_ place: SunPlace, coordinate: CLLocationCoordinate2D) {
        changeToken += 1
        SunLocation.selectLocation(false, location: coordinate, name: place.primary, sunplace: place)
        refresh()
        upgradeSelectedTimeZone()
    }

    func becameActive() {
        refresh()
        upgradeSelectedTimeZone()
        upgradeNotificationTimeZone()
    }

    private var resolvingNotificationZone = false

    private func upgradeNotificationTimeZone() {
        guard !resolvingNotificationZone, let original = SunLocation.notificationPlace, original.needsTimeZone else { return }
        resolvingNotificationZone = true
        Task {
            defer { resolvingNotificationZone = false }
            let location = CLLocation(latitude: original.latitude, longitude: original.longitude)
            guard let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location),
                  let zone = placemarks.first?.timeZone, SunLocation.notificationPlace == original else { return }
            var enriched = original
            enriched.timeZoneIdentifier = zone.identifier
            enriched.fallbackOffset = zone.secondsFromGMT()
            Defaults.defaults.set(enriched.encoded, forKey: "NotificationPlace")
            if let history = SunLocation.getLocationHistory() {
                for place in history where place.placeID == original.id &&
                    place.location?.latitude == original.latitude && place.location?.longitude == original.longitude {
                    place.timeZoneIdentifier = zone.identifier
                    place.timeZoneOffset = enriched.fallbackOffset
                }
                SunLocation.saveLocationHistory(history)
            }
            refresh()
        }
    }

    private func upgradeSelectedTimeZone() {
        guard !SunLocation.isCurrentLocation(),
              let selected = StoredPlace.saved(in: Defaults.defaults, current: false), selected.needsTimeZone else { return }
        let token = changeToken
        Task {
            let location = CLLocation(latitude: selected.latitude, longitude: selected.longitude)
            guard let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location),
                  let zone = placemarks.first?.timeZone,
                  changeToken == token, !SunLocation.isCurrentLocation(),
                  StoredPlace.saved(in: Defaults.defaults, current: false) == selected else { return }
            var updated = selected
            updated.timeZoneIdentifier = zone.identifier
            updated.fallbackOffset = zone.secondsFromGMT()
            Defaults.defaults.set(updated.encoded, forKey: "SelectedPlaceV1")
            Defaults.defaults.set(updated.fallbackOffset, forKey: "LocationTimeZoneOffset")
            if let history = SunLocation.getLocationHistory() {
                for place in history where place.placeID == updated.id {
                    place.timeZoneIdentifier = zone.identifier
                    place.timeZoneOffset = updated.fallbackOffset
                }
                SunLocation.saveLocationHistory(history)
            }
            if let notification = SunLocation.notificationPlace, notification.id == selected.id,
               notification.latitude == selected.latitude, notification.longitude == selected.longitude {
                var enriched = notification
                enriched.timeZoneIdentifier = zone.identifier
                enriched.fallbackOffset = updated.fallbackOffset
                Defaults.defaults.set(enriched.encoded, forKey: "NotificationPlace")
            }
            refresh()
        }
    }
}
