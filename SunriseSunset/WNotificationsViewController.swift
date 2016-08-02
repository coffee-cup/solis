//
//  WNotificationsViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-07-31.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class WNotificationsViewController: UIViewController {
    
    @IBOutlet weak var headingLabel: UILabel!
    
    var timer: NSTimer!
    
    let emojis = ["☀️", "🌙", "🌅", "🌄"]
    var emojiIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(updateHeading), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func updateHeading() {
        if let text = headingLabel.text {
            emojiIndex = emojiIndex + 1
            if emojiIndex >= emojis.count {
                emojiIndex = 0
            }
            let newEmoji = emojis[emojiIndex]
            
            let cutText = text.substringToIndex(text.endIndex.advancedBy(-1))
            headingLabel.text = "\(cutText)\(newEmoji)"
        }
    }
}