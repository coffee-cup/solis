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
    
    // Constraints
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    let ViewHeight: CGFloat = 110
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib
        
        if #available(iOSApplicationExtension 10.0, *) {
            leadingConstraint.constant = 20
            eventLabel.textColor = widgetDarkTextColour
            timeLabel.textColor = widgetDarkTextColour
        }
        
        setPreferred()
        setWidgetTimes()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setPreferred() {
        preferredContentSize = CGSize(width: 0, height: ViewHeight)
    }
    
    func setView(_ suntime: Suntime) {
        eventLabel.text = "\(suntime.type.event) at"
        timeLabel.text = TimeFormatters.formatter12h(TimeZone.ReferenceType.local).string(from: suntime.date)
            .replacingOccurrences(of: "AM", with: "am")
            .replacingOccurrences(of: "PM", with: "pm")
        
        // Hide for now
        imageView.isHidden = true
        imageView.image = UIImage(named: "rise_off")
    }
    
    func setSad() {
        eventLabel.text = "😔 I don't know"
        timeLabel.text = "where you are"
    }
    
    func setWidgetTimes() {
        if let location = SunLocation.getCurrentLocation() {
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
    
    func widgetPerformUpdate(_ completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        setPreferred()
        setWidgetTimes()
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
}
