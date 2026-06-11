//
//  SunPlaceTests.swift
//  SunriseSunsetTests
//

import CoreLocation
import Foundation
import Testing

@testable import SunriseSunset

struct SunPlaceTests {

    @Test func roundTripWithTimeZoneOffset() {
        let place = SunPlace(
            primary: "Vancouver",
            secondary: "BC, Canada",
            location: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
            placeID: "abc123",
            timeZoneOffset: -28800,
            isNotification: true
        )

        let parsed = SunPlace.sunPlaceFromString(place.toString!)

        #expect(parsed != nil)
        #expect(parsed?.primary == "Vancouver")
        #expect(parsed?.secondary == "BC, Canada")
        #expect(parsed?.location?.latitude == 49.2827)
        #expect(parsed?.location?.longitude == -123.1207)
        #expect(parsed?.placeID == "abc123")
        #expect(parsed?.timeZoneOffset == -28800)
        #expect(parsed?.isNotification == true)
    }

    @Test func toStringRequiresLocation() {
        let place = SunPlace(primary: "Vancouver", secondary: "BC", placeID: "abc123")

        #expect(place.toString == nil)
    }

    @Test func parseRejectsTooFewFields() {
        #expect(SunPlace.sunPlaceFromString("a|b|1.0|2.0") == nil)
        #expect(SunPlace.sunPlaceFromString("") == nil)
    }

    @Test func nilTimeZoneOffsetRoundTripIsLossy() {
        // A nil tzOffset serializes to an empty field that split(separator:) drops,
        // shifting isNotification into the tzOffset slot. Pins current behaviour.
        let place = SunPlace(
            primary: "Vancouver",
            secondary: "BC",
            location: CLLocationCoordinate2D(latitude: 49.0, longitude: -123.0),
            placeID: "abc123",
            timeZoneOffset: nil,
            isNotification: true
        )

        let parsed = SunPlace.sunPlaceFromString(place.toString!)

        #expect(parsed?.timeZoneOffset == nil)
        #expect(parsed?.isNotification == false)
    }

    @Test func equalityComparesPlaceIDOnly() {
        let a = SunPlace(primary: "A", secondary: "x", placeID: "same")
        let b = SunPlace(primary: "B", secondary: "y", placeID: "same")
        let c = SunPlace(primary: "A", secondary: "x", placeID: "different")

        #expect(a == b)
        #expect(a != c)
    }
}
