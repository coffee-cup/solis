//
//  TodayViewController.swift
//  SolisWidget
//
//  Created by Jake Runzer on 2016-06-18.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    let ViewHeight: CGFloat = 88
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib
        
        setPreferred()
        setWidgetTimes()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setPreferred() {
        preferredContentSize = CGSizeMake(0, ViewHeight)
    }
    
    func setView(suntime: Suntime) {
        eventLabel.text = "\(suntime.type.event) at"
        timeLabel.text = TimeFormatters.formatter12h(NSTimeZone.localTimeZone()).stringFromDate(suntime.date)
            .stringByReplacingOccurrencesOfString("AM", withString: "am")
            .stringByReplacingOccurrencesOfString("PM", withString: "pm")
    }
    
    func setSad() {
        eventLabel.text = "😔"
        timeLabel.text = "I don't know where you are"
    }
    
    func setWidgetTimes() {
        if let location = Location.getCurrentLocation() {
            let suntimes = SunLogic.todayTomorrow(location)
            if let nextSuntime = SunLogic.nextEvent(suntimes) {
                setView(nextSuntime)
                return
            } else {
                setSad()
            }
        } else {
            setSad()
        }
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        setPreferred()
        setWidgetTimes()
        
        completionHandler(NCUpdateResult.NewData)
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
}