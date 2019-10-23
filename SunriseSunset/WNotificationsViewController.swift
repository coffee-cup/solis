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
    
    var timer: Timer!
    
    let emojis = ["☀️", "🌙", "🌅", "🌄"]
    var emojiIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateHeading), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func updateHeading() {
        if let text = headingLabel.text {
            emojiIndex = emojiIndex + 1
            if emojiIndex >= emojis.count {
                emojiIndex = 0
            }
            let newEmoji = emojis[emojiIndex]
            
            headingLabel.text = "\(String(text.dropLast()))\(newEmoji)"
        }
    }
}
