//
//  LocationSearchView.swift
//  SunriseSunset
//

import MapKit
import SwiftUI

struct LocationSearchView: View {
    @Environment(LocationModel.self) private var locationModel

    // Picking a place closes the whole settings sheet, landing back on the
    // timeline; the settings root passes its own sheet dismiss in here.
    let onSelect: () -> Void

    @State private var model = LocationSearchModel()
    @State private var history: [SunPlace] = SunLocation.getLocationHistory() ?? []
    @State private var notificationPlaceID: String? = LocationSearchView.storedNotificationPlaceID()
    @State private var notificationPlaceDirty = false

    private var isSearching: Bool { !model.query.isEmpty }

    var body: some View {
        List {
            currentLocationRow

            if isSearching {
                ForEach(Array(model.completions.enumerated()), id: \.offset) { _, completion in
                    completionRow(completion)
                }
            } else {
                ForEach(Array(history.enumerated()), id: \.offset) { _, place in
                    historyRow(place)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .containerBackground(.clear, for: .navigation)
        .searchable(
            text: $model.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search City")
        .autocorrectionDisabled()
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if notificationPlaceDirty {
                Task {
                    await NotificationScheduler.reschedule()
                }
            }
        }
    }

    private var currentLocationRow: some View {
        HStack(spacing: 12) {
            bellButton(placeID: nil)

            VStack(alignment: .leading, spacing: 2) {
                Text("Current Location")
                if let name = SunLocation.getCurrentLocationName() {
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "location.fill")
                .foregroundStyle(.tint)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Current Location")
        .onTapGesture {
            onSelect()
            locationModel.selectCurrentLocation()
        }
    }

    private func completionRow(_ completion: MKLocalSearchCompletion) -> some View {
        placeLabels(primary: completion.title, secondary: completion.subtitle)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(completion.title), \(completion.subtitle)")
            .onTapGesture {
                onSelect()
                Task {
                    guard let coordinate = await model.resolve(completion) else { return }
                    let place = SunPlace(primary: completion.title, secondary: completion.subtitle, placeID: "")
                    place.location = coordinate
                    // Stable identity for history/notification matching now that
                    // there are no Google place IDs.
                    place.placeID = "\(coordinate.latitude),\(coordinate.longitude)"
                    locationModel.select(place, coordinate: coordinate)
                }
            }
    }

    private func historyRow(_ place: SunPlace) -> some View {
        HStack(spacing: 12) {
            bellButton(placeID: place.placeID, place: place)
            placeLabels(primary: place.primary, secondary: place.secondary)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(place.primary), \(place.secondary)")
            Spacer()
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
            if let coordinate = place.location {
                locationModel.select(place, coordinate: coordinate)
            }
        }
    }

    private func placeLabels(primary: String, secondary: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(primary)
            Text(secondary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // placeID nil = the current-location row; the bell is selected when the
    // stored notification place matches (nil matches current location).
    private func bellButton(placeID: String?, place: SunPlace? = nil) -> some View {
        let selected = notificationPlaceID == placeID
        return Button {
            setNotificationPlace(place)
            notificationPlaceID = placeID
            notificationPlaceDirty = true
        } label: {
            Image(systemName: selected ? "bell.fill" : "bell")
                .foregroundStyle(selected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(selected ? "notifications on" : "notifications off")
    }

    private func setNotificationPlace(_ place: SunPlace?) {
        place?.isNotification = true
        let value = place?.toString ?? ""
        Defaults.defaults.set(value, forKey: DefaultKey.notificationPlace.description)
    }

    private static func storedNotificationPlaceID() -> String? {
        guard let stored = Defaults.defaults.string(forKey: DefaultKey.notificationPlace.description),
              !stored.isEmpty,
              let place = SunPlace.sunPlaceFromString(stored) else {
            return nil
        }
        return place.placeID
    }
}

#Preview {
    NavigationStack {
        LocationSearchView(onSelect: {})
            .environment(LocationModel())
    }
}
