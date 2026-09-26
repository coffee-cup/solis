import CoreLocation
import Foundation
import Testing
import UserNotifications
@testable import SunriseSunset

struct LocationAndNotificationTests {
    private func withDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
        let suite = "SolisOfflineTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        try body(defaults)
    }

    @Test func freshFixIsAvailableBeforeAnyGeocoderResponse() throws {
        try withDefaults { defaults in
            let date = Date(timeIntervalSince1970:1_800_000_000)
            let revision = try #require(StoredPlace.saveFix(latitude:0,longitude:0,at:date,in:defaults))
            let saved = try #require(StoredPlace.saved(in:defaults,current:true))
            #expect(saved.latitude == 0 && saved.longitude == 0)
            #expect(saved.name == "0.0000, 0.0000")
            #expect(defaults.object(forKey:"LocationDateSet") as? Date == date)
            let widget = try #require(SunWidgetPlace.saved(in:defaults,currentLocation:true))
            #expect(widget.coordinate.latitude == 0 && widget.timeZone == .current)
            let solar = try SolarCalculator.day(containing:date,latitude:saved.latitude,longitude:saved.longitude,timeZone:widget.timeZone)
            #expect(solar.events.count >= 10)
            #expect(StoredPlace.enrichFix(name:"Gulf of Guinea",revision:revision,in:defaults))
            #expect(StoredPlace.saved(in:defaults,current:true)?.name == "Gulf of Guinea")
        }
    }

    @Test func staleGeocoderCannotOverwriteNewerFixOrSelection() throws {
        try withDefaults { defaults in
            let first = try #require(StoredPlace.saveFix(latitude:49,longitude:-123,at:Date(),in:defaults))
            let second = try #require(StoredPlace.saveFix(latitude:0,longitude:30,at:Date(),in:defaults))
            let selected = StoredPlace(name:"Tokyo",latitude:35.6762,longitude:139.6503,id:"tokyo",timeZoneIdentifier:"Asia/Tokyo")
            defaults.set(false,forKey:"CurrentLocation")
            defaults.set(selected.encoded,forKey:"SelectedPlaceV1")
            defaults.set(selected.latitude,forKey:"LocationLatitude")
            defaults.set(selected.longitude,forKey:"LocationLongitude")
            #expect(!StoredPlace.enrichFix(name:"Old fix",revision:first,in:defaults))
            #expect(StoredPlace.enrichFix(name:"New fix",revision:second,in:defaults))
            #expect(StoredPlace.saved(in:defaults,current:false) == selected)
            #expect(StoredPlace.saved(in:defaults,current:true)?.latitude == 0)
        }
    }

    @Test func invalidCoordinatesDoNotReplaceSavedFix() throws {
        try withDefaults { defaults in
            let revision = try #require(StoredPlace.saveFix(latitude:0,longitude:0,at:Date(),in:defaults))
            #expect(StoredPlace.saveFix(latitude:.nan,longitude:0,at:Date(),in:defaults) == nil)
            #expect(StoredPlace.saveFix(latitude:91,longitude:0,at:Date(),in:defaults) == nil)
            #expect(defaults.string(forKey:"CurrentFixRevision") == revision)
        }
    }

    @Test func legacyMigrationPreservesEmptyFieldsAndMarksUnresolvedZones() throws {
        let old = try #require(StoredPlace.decode("Greenwich||51.48|0|place||true"))
        #expect(old.detail.isEmpty && old.longitude == 0 && old.isNotification)
        #expect(old.needsTimeZone)
        #expect(StoredPlace.decode(try #require(old.encoded)) == old)
        for corrupt in ["A|B|nan|0|id", "A|B|91|0|id", "A|B|0|inf|id", "A|B|no|0|id", "{}"] {
            #expect(StoredPlace.decode(corrupt) == nil)
        }
    }

    @Test func namedZonesSurviveStorageAndWidgetSelectionAcrossDST() throws {
        try withDefaults { defaults in
            let place = StoredPlace(name:"New York | City",detail:"",latitude:40.7128,longitude:-74.006,id:"ny",
                                    timeZoneIdentifier:"America/New_York",fallbackOffset:-18000,isNotification:true)
            defaults.set(place.encoded,forKey:"SelectedPlaceV1")
            defaults.set(place.latitude,forKey:"LocationLatitude")
            defaults.set(place.longitude,forKey:"LocationLongitude")
            let saved = try #require(StoredPlace.saved(in:defaults,current:false))
            let widget = try #require(SunWidgetPlace.saved(in:defaults,currentLocation:false))
            #expect(saved == place && !saved.needsTimeZone)
            #expect(widget.timeZone.identifier == "America/New_York")
            var calendar = Calendar(identifier:.gregorian);calendar.timeZone = .gmt
            let winter = calendar.date(from:DateComponents(year:2026,month:1,day:1))!
            let summer = calendar.date(from:DateComponents(year:2026,month:7,day:1))!
            #expect(saved.timeZone.secondsFromGMT(for:winter) == -18000)
            #expect(saved.timeZone.secondsFromGMT(for:summer) == -14400)
        }
    }

    @Test func notificationsUseAbsoluteInstantsAndDailyFirstLightSelection() throws {
        let now = Date(timeIntervalSince1970:1_798_500_000)
        let zone = TimeZone(identifier:"Pacific/Kiritimati")!
        let coordinate = CLLocationCoordinate2D(latitude:1.8721,longitude:-157.4278)
        let times = SunLogic.todayTomorrow(coordinate,now:now,timezone:zone)
        let widgetDays = SunWidgetData.days(from:now,location:coordinate,timeZone:zone)
        let snapshot = SunWidgetData.snapshot(at:now,locationName:"Kiritimati",timeZone:zone,days:widgetDays)
        let next = try #require(SunLogic.nextEvent(times,now:now))
        #expect(snapshot.nextEvent?.date == next.date)
        for alert in SunAlert.allCases {
            let event = try #require(alert.nextTime(in:times,now:now))
            let trigger = NotificationScheduler.trigger(for:event.date)
            #expect(trigger.dateComponents.timeZone == .gmt)
            #expect(trigger.dateComponents.calendar?.identifier == .gregorian)
            let restored = try #require(trigger.dateComponents.date)
            #expect(restored >= event.date && restored.timeIntervalSince(event.date) < 1)
            #expect(!trigger.repeats)
        }
        let polar = SunLogic.todayTomorrow(CLLocationCoordinate2D(latitude:90,longitude:0),now:now,timezone:.gmt)
        #expect(SunAlert.sunrise.nextTime(in:polar,now:now) == nil)
    }
    @Test func structuredPlaceIsAtomicAndDoesNotRequireLegacyKeys() throws {
        try withDefaults { defaults in
            let place = StoredPlace(name: "Saved offline", latitude: 0, longitude: 0, id: "saved", timeZoneIdentifier: "GMT")
            defaults.set(place.encoded, forKey: "SelectedPlaceV1")
            #expect(StoredPlace.saved(in: defaults, current: false) == place)
            defaults.set(80.0, forKey: "LocationLatitude")
            defaults.set(120.0, forKey: "LocationLongitude")
            #expect(StoredPlace.saved(in: defaults, current: false) == place)
        }
    }

}
