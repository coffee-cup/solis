import Foundation

/// Versioned storage shared by the app and widget. A legacy offset is usable
/// offline, but remains explicitly unresolved until a named zone is obtained.
nonisolated struct StoredPlace: Codable, Equatable, Sendable {
    let version: Int
    var name: String
    var detail: String
    let latitude: Double
    let longitude: Double
    let id: String
    var timeZoneIdentifier: String?
    var fallbackOffset: Int?
    var isNotification: Bool

    init(name: String, detail: String = "", latitude: Double, longitude: Double, id: String,
         timeZoneIdentifier: String? = nil, fallbackOffset: Int? = nil, isNotification: Bool = false) {
        version = 1
        self.name = name; self.detail = detail; self.latitude = latitude; self.longitude = longitude; self.id = id
        self.timeZoneIdentifier = timeZoneIdentifier; self.fallbackOffset = fallbackOffset; self.isNotification = isNotification
    }

    var isValid: Bool {
        version == 1 && latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude)
            && (timeZoneIdentifier == nil || TimeZone(identifier: timeZoneIdentifier!) != nil)
            && (fallbackOffset == nil || TimeZone(secondsFromGMT: fallbackOffset!) != nil)
    }
    var needsTimeZone: Bool { timeZoneIdentifier == nil }
    var timeZone: TimeZone {
        timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? fallbackOffset.flatMap(TimeZone.init(secondsFromGMT:)) ?? .gmt
    }
    var encoded: String? {
        guard isValid, let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func decode(_ string: String) -> Self? {
        if let data = string.data(using: .utf8), let value = try? JSONDecoder().decode(Self.self, from: data) {
            return value.isValid ? value : nil
        }
        let fields = string.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 5, let lat = Double(fields[2]), let lon = Double(fields[3]) else { return nil }
        let value = Self(name: fields[0], detail: fields[1], latitude: lat, longitude: lon, id: fields[4],
                         fallbackOffset: fields.count > 5 ? Int(fields[5]) : nil,
                         isNotification: fields.count > 6 && fields[6] == "true")
        return value.isValid ? value : nil
    }

    static func saved(in defaults: UserDefaults, current: Bool) -> Self? {
        let key = current ? "CurrentPlaceV1" : "SelectedPlaceV1"
        let prefix = current ? "CurrentLocation" : "Location"
        let arguments = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
        let hasCoordinateOverride = arguments[prefix+"Latitude"] != nil && arguments[prefix+"Longitude"] != nil
        // The complete record is one atomic defaults value. Launch-argument
        // coordinate overrides intentionally take precedence for deterministic UI fixtures.
        if !hasCoordinateOverride, let raw = defaults.string(forKey: key), let stored = decode(raw) { return stored }
        guard let lat = defaults.object(forKey: prefix+"Latitude") as? Double,
              let lon = defaults.object(forKey: prefix+"Longitude") as? Double else { return nil }
        let stored = Self(name: defaults.string(forKey: prefix+"Name") ?? "\(lat), \(lon)", latitude: lat, longitude: lon,
                          id: defaults.string(forKey: "LocationPlaceID") ?? "\(lat),\(lon)",
                          fallbackOffset: current ? nil : defaults.object(forKey: "LocationTimeZoneOffset") as? Int)
        return stored.isValid ? stored : nil
    }
    @discardableResult
    static func saveFix(latitude: Double, longitude: Double, at date: Date, in defaults: UserDefaults) -> String? {
        let place = Self(name: String(format: "%.4f, %.4f", latitude, longitude), latitude: latitude, longitude: longitude, id: "current")
        guard let encoded = place.encoded else { return nil }
        let revision = UUID().uuidString
        defaults.set(revision, forKey: "CurrentFixRevision")
        defaults.set(encoded, forKey: "CurrentPlaceV1")
        defaults.set(latitude, forKey: "CurrentLocationLatitude")
        defaults.set(longitude, forKey: "CurrentLocationLongitude")
        defaults.set(place.name, forKey: "CurrentLocationName")
        defaults.set(date, forKey: "LocationDateSet")
        return revision
    }

    @discardableResult
    static func enrichFix(name: String, revision: String, in defaults: UserDefaults) -> Bool {
        guard defaults.string(forKey: "CurrentFixRevision") == revision,
              var place = saved(in: defaults, current: true) else { return false }
        place.name = name
        defaults.set(place.encoded, forKey: "CurrentPlaceV1")
        defaults.set(name, forKey: "CurrentLocationName")
        return true
    }

}
