//
//  Location.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-20.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftLocation

class SunLocation {
    
    static let defaults = Defaults.defaults
    
    static let CHECK_THRESHOLD = 60 * 10; // seconds
    
    class func startLocationWatching() {
        let _ = Location.getLocation(withAccuracy: .block, frequency: .significant, timeout: nil, onSuccess: { (location) in
            print("Significant Location")
            saveLocation(location.coordinate)
        }) { (lastValidLocation, error) in
            print(error)
        }
    }
    
    class func checkLocation() {
        let _ = Location.getLocation(withAccuracy: .block, frequency: .oneShot, timeout: nil, onSuccess: { (location) in
            print("\nOne Shot Location")
            saveLocation(location.coordinate)
        }) { (lastValidLocation, error) in
            print(error)
        }
    }
    
    class func getCurrentLocation() -> CLLocationCoordinate2D? {
        let latitude = defaults.double(forKey: DefaultKey.currentLocationLatitude.description)
        let longitude = defaults.double(forKey: DefaultKey.currentLocationLongitude.description)
        
        if latitude == 0 || longitude == 0 {
            return nil
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    class func getLocation() -> CLLocationCoordinate2D? {
        let latitude = defaults.double(forKey: DefaultKey.locationLatitude.description)
        let longitude = defaults.double(forKey: DefaultKey.locationLongitude.description)
        
        if latitude == 0 || longitude == 0 {
            return nil
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    class func getNotificationLocation() -> CLLocationCoordinate2D? {
        if let sunPlaceString = defaults.object(forKey: DefaultKey.notificationPlace.description) as? String {
            let sunPlace = SunPlace.sunPlaceFromString(sunPlaceString)
            if let sunPlace = sunPlace {
                if let location = sunPlace.location {
                    print("notification for \(sunPlace.primary)")
                    return location
                }
            }
        }
        print("notification for current location")
        return getCurrentLocation()
    }
    
    class func getPlaceID() -> String? {
        return defaults.string(forKey: DefaultKey.locationPlaceID.description)
    }
    
    class func getLocationName() -> String? {
        return defaults.string(forKey: DefaultKey.locationName.description)
    }
    
    class func getCurrentLocationName() -> String? {
        return defaults.string(forKey: DefaultKey.currentLocationName.description)
    }
    
    class func isCurrentLocation() -> Bool {
        return defaults.bool(forKey: DefaultKey.currentLocation.description)
    }
    
    class func lookupLocation(_ coordinate: CLLocationCoordinate2D, completion: @escaping (_ placemark: CLPlacemark?) -> ()) {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if let err = error{
                print("Error Reverse Geocoding Location: \(err.localizedDescription)")
                completion(nil)
                return
            }
            completion(placemarks![0])
        })
    }
    
    class func setLocation(_ current: Bool, location: CLLocationCoordinate2D, name: String, sunplace: SunPlace? = nil) {
        defaults.set(name, forKey: DefaultKey.locationName.description)
        defaults.set(location.latitude, forKey: DefaultKey.locationLatitude.description)
        defaults.set(location.longitude, forKey: DefaultKey.locationLongitude.description)
        defaults.set(current, forKey: DefaultKey.currentLocation.description)
        
        if !current {
            defaults.set(sunplace?.placeID, forKey: DefaultKey.locationPlaceID.description)
            Bus.sendMessage(.fetchTimeZone, data: nil)
        }
    
        notifyLocation()
    }
    
    class func selectLocation(_ current: Bool, location: CLLocationCoordinate2D?, name: String?, sunplace: SunPlace?) {
        if current {
            if let currentLocation = getCurrentLocation() {
                if let locationName = getCurrentLocationName() {
                    notifyLocationChanged()
                    setLocation(true, location: currentLocation, name: locationName)
                }
            }
            checkLocation()
        } else {
            if let sunplace = sunplace {
                notifyLocationChanged()
                setLocation(false, location: location!, name: name!, sunplace: sunplace)
                addLocationToHistory(sunplace)
                if let timeZoneOffset = sunplace.timeZoneOffset {
                    print("setting timezone offset from saved \(timeZoneOffset)")
                    Defaults.defaults.set(timeZoneOffset, forKey: DefaultKey.locationTimeZoneOffset.description)
                }
            }
        }
        Bus.sendMessage(.locationUpdate, data: nil)
    }
    
    class func updateLocationHistoryWithTimeZone(_ location: CLLocationCoordinate2D, placeID: String, timeZoneOffset: Int) {
        if let locationHistory = getLocationHistory() {
            let index = locationHistory.index { place in
                return place.placeID == placeID
            }
            if let index = index {
                if index >= 0 && index < locationHistory.count {
                    let sunplace = locationHistory[index]
                    sunplace.timeZoneOffset = timeZoneOffset
                    print("saving timezoneoffset to history \(timeZoneOffset)")
                    addLocationToHistory(sunplace)
                }
            }
        }
    }
    
    class func getLocationHistory() -> [SunPlace]? {
        if let locationHistoryPlaces = defaults.object(forKey: DefaultKey.locationHistoryPlaces.description) as? [String] {
            var places: [SunPlace] = []
            for placeString in locationHistoryPlaces {
                if let sunplace = SunPlace.sunPlaceFromString(placeString) {
                    places.append(sunplace)
                }
            }
            return places
        }
        return nil
    }
    
    class func saveLocationHistory(_ places: [SunPlace]) {
        var sunPlaceString = defaults.object(forKey: DefaultKey.notificationPlace.description) as? String
        sunPlaceString = sunPlaceString == nil ? "" : sunPlaceString
        var notificationSunPlace: SunPlace? = nil
        if let sunPlaceString = sunPlaceString {
            notificationSunPlace = SunPlace.sunPlaceFromString(sunPlaceString)
        }
        
        let placeStrings: [String] = places.map { place in
            if let notificationSunPlace = notificationSunPlace {
                if notificationSunPlace.placeID == place.placeID {
                    place.isNotification = true
                } else {
                    place.isNotification = false
                }
            } else {
                place.isNotification = false
            }
            if let placeString = place.toString {
                return placeString
            }
            return ""
        }
        defaults.set(placeStrings, forKey: DefaultKey.locationHistoryPlaces.description)
    }
    
    class func addLocationToHistory(_ sunplace: SunPlace) {
        if var locationHistory: [SunPlace] = getLocationHistory() {
            if let index = locationHistory.index(of: sunplace) {
                locationHistory.remove(at: index)
            }
            
            locationHistory.insert(sunplace, at: 0)
            
            if locationHistory.count > 5 {
                locationHistory = Array(locationHistory[0...4])
            }
            
            saveLocationHistory(locationHistory)
        }
    }
    
    // Returns if we need to update the location
    class func needCheck() -> Bool {
        if defaults.double(forKey: DefaultKey.locationLatitude.description) == 0 ||
            defaults.double(forKey: DefaultKey.locationLongitude.description) == 0 {
            return true
        }
        
        guard let date = defaults.object(forKey: DefaultKey.locationDateSet.description) else {
            return false
        }
        
        guard let differenceSeconds = (date as AnyObject).timeIntervalSinceNow else {
            return false
        }
        
        return (Int(differenceSeconds)) > CHECK_THRESHOLD
    }
    
    class func notifyLocation() {
        Bus.sendMessage(.locationUpdate, data: nil)
    }
    
    class func notifyLocationChanged() {
        Bus.sendMessage(.locationChanged, data: nil)
    }
    
    class func saveLocation(_ location: CLLocationCoordinate2D) {
        let now = Date()
        
        lookupLocation(location) { placemark in
            var name = ""
            if let placemark = placemark {
                if let city = placemark.locality {
                    name = city
                    defaults.set(location.latitude, forKey: DefaultKey.currentLocationLatitude.description)
                    defaults.set(location.longitude, forKey: DefaultKey.currentLocationLongitude.description)
                    defaults.set(name, forKey: DefaultKey.currentLocationName.description)
                    if isCurrentLocation() {
                        setLocation(true, location: location, name: name)
                        defaults.set(now, forKey: DefaultKey.locationDateSet.description)
                    }
                }
            }
        }
    }
}
