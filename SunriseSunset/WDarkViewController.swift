//
//  WDarkViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-07-31.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class WDarkViewController: UIViewController {
    
    @IBOutlet weak var headingLabel: UILabel!
    
    var timer: Timer!
    
    let worldEmojis = ["🌎", "🌏", "🌍"]
    var emojiIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emojiIndex = worldEmojis.count
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateHeading), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func updateHeading() {
        if let text = headingLabel.text {
            emojiIndex = emojiIndex + 1
            if emojiIndex >= worldEmojis.count {
                emojiIndex = 0
            }
            let newEmoji = worldEmojis[emojiIndex]
            
            let cutText = text.substring(to: text.index(text.endIndex, offsetBy: -1))
            headingLabel.text = "\(cutText)\(newEmoji)"
        }
    }
}
