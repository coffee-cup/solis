//
//  LocationSearchModel.swift
//  SunriseSunset
//

import CoreLocation
import MapKit
import Observation

@MainActor
@Observable
final class LocationSearchModel: NSObject, @preconcurrency MKLocalSearchCompleterDelegate {

    var query: String = "" {
        didSet {
            if query.isEmpty {
                completer.cancel()
                completions = []
            } else {
                completer.queryFragment = query
            }
        }
    }

    private(set) var completions: [MKLocalSearchCompletion] = []

    // .address (not .locality) on purpose: the locality filter returns zero
    // results on recent simulators.
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Autocomplete error \(error)")
    }

    func resolve(_ completion: MKLocalSearchCompletion) async -> SunPlace? {
        let search = MKLocalSearch(request: MKLocalSearch.Request(completion: completion))
        guard let response = try? await search.start() else { return nil }
        guard let item = response.mapItems.first else { return nil }
        let coordinate = item.placemark.coordinate
        let place = SunPlace(primary: completion.title, secondary: completion.subtitle,
                             location: coordinate, placeID: "\(coordinate.latitude),\(coordinate.longitude)",
                             timeZoneOffset: item.timeZone?.secondsFromGMT(), isNotification: false)
        place.timeZoneIdentifier = item.timeZone?.identifier
        return place
    }
}
