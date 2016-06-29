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
    
    static var currentTimeZone: NSTimeZone {
        if Location.isCurrentLocation() {
            return NSTimeZone.localTimeZone()
        }
        if let timeZone = getTimeZone() {
            return timeZone
        }
        
        return NSTimeZone.localTimeZone()
    }
    
    init() {
        Bus.subscribeEvent(.FetchTimeZone, observer: self, selector: #selector(fetchTimeZone))
    }
    
    @objc func fetchTimeZone() {
        if let location = Location.getLocation() {
            timeZoneForLocation(location) { gmtOffset, abbreviation in
                guard let gmtOffset = gmtOffset else {
                    return
                }
                
                guard let abbreviation = abbreviation else {
                    return
                }
                
//                print("gmt offset: \(gmtOffset)")
//                print("abb: \(abbreviation)")
                self.saveTimeZone(gmtOffset, abbreviation: abbreviation)
            }
        }
    }
    
    func saveTimeZone(gmtOffset: Int, abbreviation: String) {
        Defaults.defaults.setObject(abbreviation, forKey: DefaultKey.LocationTimeZoneAbbreviation.description)
        Defaults.defaults.setInteger(gmtOffset, forKey: DefaultKey.LocationTimeZoneOffset.description)
        Bus.sendMessage(.GotTimeZone, data: nil )
    }
    
    class func getTimeZone() -> NSTimeZone? {
        let gmtOffset = Defaults.defaults.integerForKey(DefaultKey.LocationTimeZoneOffset.description)
        if let abbreviation = Defaults.defaults.stringForKey(DefaultKey.LocationTimeZoneAbbreviation.description) {
            let timeZone = NSTimeZone(forSecondsFromGMT: gmtOffset)
            return timeZone
        }
        return nil
    }
    
    func timeZoneForLocation(location: CLLocationCoordinate2D, completionHandler: (gmtOffset: Int?, abbreviation: String?) -> ()) {
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