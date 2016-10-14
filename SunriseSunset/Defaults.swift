//
//  Defaults.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-18.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation

enum DefaultKey {
    case timeFormat
    case firstLight
    case lastLight
    case sunrise
    case sunset
    case notificationPreTime
    case currentLocation
    case locationName
    case currentLocationName
    case locationDateSet
    case currentLocationLatitude
    case currentLocationLongitude
    case locationLatitude
    case locationLongitude
    case locationPlaceID
    case locationTimeZoneOffset
    case locationHistoryPlaces
    case showWalkthrough
    case showTutorial
    case showSunAreas
    case notificationPlace
    
    var description: String {
        switch self {
        case .timeFormat: return "TimeFormat"
        case .firstLight: return "FirstLight"
        case .lastLight: return "LastLight"
        case .sunrise: return "Sunrise"
        case .sunset: return "Sunset"
        case .notificationPreTime: return "NotificationPreTime"
        case .currentLocation: return "CurrentLocation"
        case .locationName: return "LocationName"
        case .currentLocationName: return "CurrentLocationName"
        case .locationDateSet: return "LocationDateSet"
        case .currentLocationLatitude: return "CurrentLocationLatitude"
        case .currentLocationLongitude: return "CurrentLocationLongitude"
        case .locationLatitude: return "LocationLatitude"
        case .locationLongitude: return "LocationLongitude"
        case .locationPlaceID: return "LocationPlaceID"
        case .locationTimeZoneOffset: return "LocationTimeZoneOffset"
        case .locationHistoryPlaces: return "LocationHistoryPlaces"
        case .showWalkthrough: return "ShowWalkthrough"
        case .showTutorial: return "ShowTutorial"
        case .showSunAreas: return "ShowSunAreas"
        case .notificationPlace: return "NotificationPlace"
        }
    }
}

class Defaults {
    static let defaults = UserDefaults.init(suiteName: "group.SunriseSunset")!
    
    static var delta: Bool {
        let timeformat = defaults.string(forKey: MessageType.timeFormat.description)
        return timeformat == "delta"
    }
    
    static var timeFormat: String {
        return defaults.string(forKey: DefaultKey.timeFormat.description)!
    }
    
    static var showWalkthrough: Bool {
        get {
            return defaults.bool(forKey: DefaultKey.showWalkthrough.description)
        }
        set {
            defaults.set(newValue, forKey: DefaultKey.showWalkthrough.description)
        }
    }
    
    static var showSunAreas: Bool {
        get {
            return defaults.bool(forKey: DefaultKey.showSunAreas.description)
        }
        set {
            defaults.set(newValue, forKey: DefaultKey.showSunAreas.description)
        }
    }
}
