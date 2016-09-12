//
//  NSAttributedString.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-08-03.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    enum AtributeSearchType {
        case first, all, last
    }
    
    func attributeRangeFor(_ searchString: String, attributeName: String, attributeValue: AnyObject, atributeSearchType: AtributeSearchType) {
        let inputLength = self.string.characters.count
        let searchLength = searchString.characters.count
        var range = NSRange(location: 0, length: self.length)
        var rangeCollection = [NSRange]()
        
        while (range.location != NSNotFound) {
            range = (self.string as NSString).range(of: searchString, options: [], range: range)
            if (range.location != NSNotFound) {
                switch atributeSearchType {
                case .first:
                    self.addAttribute(attributeName, value: attributeValue, range: NSRange(location: range.location, length: searchLength))
                    return
                case .all:
                    self.addAttribute(attributeName, value: attributeValue, range: NSRange(location: range.location, length: searchLength))
                    break
                case .last:
                    rangeCollection.append(range)
                    break
                }
                
                range = NSRange(location: range.location + range.length, length: inputLength - (range.location + range.length))
            }
        }
        
        switch atributeSearchType {
        case .last:
            let indexOfLast = rangeCollection.count - 1
            self.addAttribute(attributeName, value: attributeValue, range: rangeCollection[indexOfLast])
            break
        default:
            break
        }
    }
}
