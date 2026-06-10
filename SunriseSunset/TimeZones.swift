//
//  TimeZone.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-27.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import CoreLocation

class TimeZones {

    static var currentTimeZone: TimeZone {
        if SunLocation.isCurrentLocation() {
            return TimeZone.ReferenceType.local
        }
        if let timeZone = getTimeZone() {
            return timeZone
        }

        return TimeZone.ReferenceType.local
    }

    init() {
        Bus.subscribeEvent(.fetchTimeZone, observer: self, selector: #selector(fetchTimeZone))
    }

    @objc func fetchTimeZone() {
        if let location = SunLocation.getLocation() {
            timeZoneForLocation(location) { gmtOffset in
                guard let gmtOffset = gmtOffset else {
                    return
                }

                self.saveTimeZone(gmtOffset)

                if !SunLocation.isCurrentLocation() {
                    if let placeID = SunLocation.getPlaceID() {
                        SunLocation.updateLocationHistoryWithTimeZone(location, placeID: placeID, timeZoneOffset: gmtOffset)
                    }
                }
            }
        }
    }

    func saveTimeZone(_ gmtOffset: Int) {
        Defaults.defaults.set(gmtOffset, forKey: DefaultKey.locationTimeZoneOffset.description)
        Bus.sendMessage(.gotTimeZone, data: nil )
    }

    class func getTimeZone() -> TimeZone? {
        let gmtOffset = Defaults.defaults.integer(forKey: DefaultKey.locationTimeZoneOffset.description)
        let timeZone = TimeZone(secondsFromGMT: gmtOffset)
        return timeZone
    }

    func timeZoneForLocation(_ location: CLLocationCoordinate2D, completionHandler: @escaping (_ gmtOffset: Int?) -> ()) {
        let location = CLLocation(latitude: location.latitude, longitude: location.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            guard let timeZone = placemarks?.first?.timeZone else {
                print("Reverse geocode returned no time zone: \(error?.localizedDescription ?? "unknown error")")
                completionHandler(nil)
                return
            }
            completionHandler(timeZone.secondsFromGMT(for: Date()))
        }
    }

}
