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

class TimeZones {
    
    let ApiKey = "3GEZEJL3FJ03"
    let Endpoint = "https://api.timezonedb.com/v2/get-time-zone"
    
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
            timeZoneForLocation(location) { gmtOffset, abbreviation in
                guard let gmtOffset = gmtOffset else {
                    return
                }
                
//                print("gmt offset: \(gmtOffset)")
//                print("abb: \(abbreviation)")
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
    
    func timeZoneForLocation(_ location: CLLocationCoordinate2D, completionHandler: @escaping (_ gmtOffset: Int?, _ abbreviation: String?) -> ()) {
        let requestString = "\(Endpoint)?by=position&format=json&key=\(ApiKey)&lat=\(location.latitude)&lng=\(location.longitude)"
        AF.request(requestString)
        .responseJSON { response in
//            print(response.request)  // original URL request
//            print(response.response) // URL response
//            print(response.data)     // server data
//            print(response.result)   // result of response serialization
        
            guard let data = response.data else {
                print("Data from response is nil")
                completionHandler(nil, nil)
                return
            }
            
            let json = try! JSON(data: data)
            guard let abbreviation = json["abbreviation"].string else {
                print("Abbreviation from response is nil")
                completionHandler(nil, nil)
                return
            }
            
            guard let gmtOffset = json["gmtOffset"].int else {
                print("GmtOffset from response is nil")
                completionHandler(nil, nil)
                return
            }
            
//            guard let dst = json["dst"].string else {
//                print("DST from response is nil")
//                completionHandler(nil, nil)
//                return
//            }
            
//            let daylightSavings = dst == "1"
            let offsetWithGmt = gmtOffset
//            if daylightSavings {
//                offsetWithGmt += 60 * 60
//            }
            completionHandler(offsetWithGmt, abbreviation)
        }
    }
    
}
