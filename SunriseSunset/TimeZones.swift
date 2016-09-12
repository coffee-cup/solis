//
//  TimeZone.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-27.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON

class TimeZones {
    
    let ApiKey = "3GEZEJL3FJ03"
    let Endpoint = "https://api.timezonedb.com/v2/get-time-zone"
    
    static var currentTimeZone: TimeZone {
        if Location.isCurrentLocation() {
            return TimeZone.local()
        }
        if let timeZone = getTimeZone() {
            return timeZone
        }
        
        return TimeZone.local()
    }
    
    init() {
        Bus.subscribeEvent(.fetchTimeZone, observer: self, selector: #selector(fetchTimeZone))
    }
    
    @objc func fetchTimeZone() {
        if let location = Location.getLocation() {
            timeZoneForLocation(location) { gmtOffset, abbreviation in
                guard let gmtOffset = gmtOffset else {
                    return
                }
                
//                print("gmt offset: \(gmtOffset)")
//                print("abb: \(abbreviation)")
                self.saveTimeZone(gmtOffset)
                
                if !Location.isCurrentLocation() {
                    if let placeID = Location.getPlaceID() {
                        Location.updateLocationHistoryWithTimeZone(location, placeID: placeID, timeZoneOffset: gmtOffset)
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
    
    func timeZoneForLocation(_ location: CLLocationCoordinate2D, completionHandler: @escaping (_ gmtOffset: Int?, _ abbreviation: String?) -> ()) {
        Alamofire.request(.GET, Endpoint, parameters: [
            "key": ApiKey,
            "by": "position",
            "format": "json",
            "lat": location.latitude,
            "lng": location.longitude            
        ])
        .responseJSON { response in
//                print(response.request)  // original URL request
//                print(response.response) // URL response
//                print(response.data)     // server data
//                print(response.result)   // result of response serialization
            
            guard let data = response.data else {
                print("Data from response is nil")
                completionHandler(gmtOffset: nil, abbreviation: nil)
                return
            }
            
            let json = JSON(data: data)
            guard let abbreviation = json["abbreviation"].string else {
                print("Abbreviation from response is nil")
                completionHandler(gmtOffset: nil, abbreviation: nil)
                return
            }
            
            guard let gmtOffset = json["gmtOffset"].int else {
                print("GmtOffset from response is nil")
                completionHandler(gmtOffset: nil, abbreviation: nil)
                return
            }
            
            guard let dst = json["dst"].string else {
                print("DST from response is nil")
                completionHandler(gmtOffset: nil, abbreviation: nil)
                return
            }
            
            let daylightSavings = dst == "1"
            var offsetWithGmt = gmtOffset
//            if daylightSavings {
//                offsetWithGmt += 60 * 60
//            }
            completionHandler(gmtOffset: offsetWithGmt, abbreviation: abbreviation)
        }
    }
    
}
