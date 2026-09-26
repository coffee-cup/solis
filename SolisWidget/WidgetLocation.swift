import AppIntents
import MapKit

struct WidgetLocation: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Location" }
    static var defaultQuery: WidgetLocationQuery { WidgetLocationQuery() }

    let id: String
    let name: String
    let detail: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(detail)")
    }

    static let followApp = WidgetLocation(id: "app", name: "Follow Solis", detail: "The location selected in the app")
    static let current = WidgetLocation(id: "current", name: "Current location", detail: "Last location from Solis")

    init(id: String, name: String, detail: String) {
        self.id = id
        self.name = name
        self.detail = detail
    }

    init(place: SunWidgetPlace) {
        self.init(id: place.identifier, name: place.name, detail: place.detail)
    }

    var resolvedPlace: SunWidgetPlace? {
        switch id {
        case "app": SunWidgetPlace.saved(in: Defaults.defaults)
        case "current": SunWidgetPlace.saved(in: Defaults.defaults, currentLocation: true)
        default: SunWidgetPlace(identifier: id)
        }
    }
}

struct WidgetLocationQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [WidgetLocation] {
        identifiers.compactMap { id in
            switch id {
            case "app": .followApp
            case "current": .current
            default: SunWidgetPlace(identifier: id).map {
                WidgetLocation(id: id, name: $0.name, detail: $0.detail)
            }
            }
        }
    }

    func suggestedEntities() async throws -> [WidgetLocation] {
        [.followApp, .current]
    }

    func defaultResult() async -> WidgetLocation? { .followApp }

    func entities(matching string: String) async throws -> [WidgetLocation] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return try await suggestedEntities() }
        return try await Self.search(query)
    }

    @MainActor
    private static func search(_ query: String) async throws -> [WidgetLocation] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .address
        let response = try await MKLocalSearch(request: request).start()
        var seen = Set<String>()
        return response.mapItems.compactMap { item in
            guard let zone = item.timeZone else { return nil }
            let placemark = item.placemark
            let name = placemark.locality ?? item.name ?? query
            let detail = [placemark.administrativeArea, placemark.country].compactMap { $0 }.joined(separator: ", ")
            guard seen.insert(name + ", " + detail).inserted else { return nil }
            return WidgetLocation(place: SunWidgetPlace(
                name: name, detail: detail,
                latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude,
                timeZoneIdentifier: zone.identifier))
        }
    }
}

struct SunWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Widget settings" }
    static var description: IntentDescription { "Choose a location and theme." }

    @Parameter(title: "Location")
    var location: WidgetLocation?

    @Parameter(title: "Theme", default: .followApp)
    var theme: WidgetTheme
}

enum WidgetTheme: String, AppEnum {
    case followApp, classic, ember, midnight, aurora, infrared

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Theme" }
    static var caseDisplayRepresentations: [WidgetTheme: DisplayRepresentation] {
        [.followApp: "Follow Solis", .classic: "Classic", .ember: "Ember",
         .midnight: "Midnight", .aurora: "Aurora", .infrared: "Infrared"]
    }

    var sunTheme: SunTheme {
        self == .followApp ? .current : (SunTheme(rawValue: rawValue) ?? .classic)
    }
}
