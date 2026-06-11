//
//  LocationSearchView.swift
//  SunriseSunset
//

import MapKit
import SwiftUI

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationModel.self) private var locationModel

    @State private var model = LocationSearchModel()
    @State private var history: [SunPlace] = SunLocation.getLocationHistory() ?? []
    @State private var notificationPlaceID: String? = LocationSearchView.storedNotificationPlaceID()
    @State private var notificationPlaceDirty = false
    @FocusState private var searchFocused: Bool

    private var isSearching: Bool { !model.query.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            searchBar

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
        }
        .background(Color.white)
        .onAppear { searchFocused = true }
        .onDisappear {
            if notificationPlaceDirty {
                Task {
                    await NotificationScheduler.reschedule()
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search City", text: $model.query)
                    .focused($searchFocused)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("citySearchField")
            }
            .padding(8)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.primary)
                    .padding(8)
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var currentLocationRow: some View {
        HStack(spacing: 12) {
            bellButton(placeID: nil)

            VStack(alignment: .leading, spacing: 2) {
                Text("Current Location")
                    .font(.custom(fontRegular, size: 16))
                if let name = SunLocation.getCurrentLocationName() {
                    Text(name)
                        .font(.custom(fontLight, size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image("location")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
        .frame(height: 48)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Current Location")
        .onTapGesture {
            dismiss()
            locationModel.selectCurrentLocation()
        }
    }

    private func completionRow(_ completion: MKLocalSearchCompletion) -> some View {
        placeLabels(primary: completion.title, secondary: completion.subtitle)
            .frame(height: 48)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(completion.title), \(completion.subtitle)")
            .onTapGesture {
                dismiss()
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
        .frame(height: 48)
        .contentShape(Rectangle())
        .onTapGesture {
            dismiss()
            if let coordinate = place.location {
                locationModel.select(place, coordinate: coordinate)
            }
        }
    }

    private func placeLabels(primary: String, secondary: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(primary)
                .font(.custom(fontRegular, size: 16))
            Text(secondary)
                .font(.custom(fontLight, size: 12))
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
            Image(selected ? "bell_red" : "bell_grey")
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
