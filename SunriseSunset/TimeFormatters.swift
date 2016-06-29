//
//  TimeFormatters.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-19.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation

enum TimeFormat {
    case hour24
    case hour12
    case delta
    
    var description: String {
        switch(self) {
        case .hour24: return "HH:mm"
        case .hour12: return "h:mm a"
        case .delta: return "delta"
        }
    }
}

class TimeFormatters {
    static func timeFormatter(format: String, timeZone: NSTimeZone) -> NSDateFormatter {
        let timeFormatter = NSDateFormatter()
        timeFormatter.timeZone = timeZone
        timeFormatter.dateFormat = format
        return timeFormatter
    }
    
    // Create single instance of date formatter for each time zone
    // When time zone changes, create new date formatter
    static var formatter12hInstance = TimeFormatters.timeFormatter(TimeFormat.hour12.description, timeZone: NSTimeZone.localTimeZone())
    class func formatter12h(timeZone: NSTimeZone) -> NSDateFormatter {
        return formatter12hInstance.timeZone == timeZone ? formatter12hInstance : timeFormatter(TimeFormat.hour12.description, timeZone: timeZone)
    }
    
    static var formatter24hInstance = TimeFormatters.timeFormatter(TimeFormat.hour24.description, timeZone: NSTimeZone.localTimeZone())
    class func formatter24h(timeZone: NSTimeZone) -> NSDateFormatter {
        return formatter24hInstance.timeZone == timeZone ? formatter12hInstance : timeFormatter(TimeFormat.hour24.description, timeZone: timeZone)
    }
    
    static func currentFormatter(timeZone: NSTimeZone) -> NSDateFormatter? {
        let timeFormat = Defaults.timeFormat
        if timeFormat == TimeFormat.hour12.description {
            return formatter12h(timeZone)
        } else if timeFormat == TimeFormat.hour24.description {
            return formatter24h(timeZone)
        }
        return nil
    }
    
    static func currentFormattedString(time: NSDate, timeZone: NSTimeZone) -> String {
        var text = ""
        
        let timeOffset = time.dateByAddingTimeInterval(0) // may have to change
        let hours = timeOffset.getHoursToNow()
        let minutes = timeOffset.getMinutesToNow()
        let hourMinutes = abs(minutes - (hours * 60))
        let inPast = timeOffset.timeIntervalSinceNow < 0
        
        if Defaults.delta {
            text += inPast ? "- " : "+ "
            if hours != 0 {
                text += "\(hours)h"
            }
            if hours != 0 && hourMinutes != 0 {
                text += " "
            }
            if hourMinutes != 0 {
                text += "\(hourMinutes)m"
            }
            if hours == 0 && hourMinutes == 0 {
                text = "--"
            }
        } else {
            if let formatter = currentFormatter(timeZone) {
                text = formatter.stringFromDate(time)
                text = text.stringByReplacingOccurrencesOfString("AM", withString: "am")
                text = text.stringByReplacingOccurrencesOfString("PM", withString: "pm")
            }
        }
        return text

    }
}