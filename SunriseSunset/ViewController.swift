//
//  ViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-14.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import UIKit
import EDSunriseSet
import CoreLocation
import PermissionScope

class ViewController: UIViewController {

    @IBOutlet weak var sunView: UIView!
    @IBOutlet weak var hourSlider: UISlider!
    var gradientLayer = CAGradientLayer()
    
    @IBOutlet weak var nowTimeLabel: UILabel!
    @IBOutlet weak var nowLineView: UIView!
    @IBOutlet weak var nowLabel: UILabel!
    
    var myLoc: CLLocationCoordinate2D!
    
    var sun: Sun!
    
    var offset: Float = 0
    var timer = NSTimer()
    
    let pscope = PermissionScope()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        Sun.timeFormatter.dateFormat = "HH:mm"
        
        let screenMinutes = Float(6 * 60)
        let screenHeight = Float(view.frame.height)
        let sunHeight = Float(sunView.frame.height)
        
        sunView.layer.addSublayer(gradientLayer)
        
        nowLabel.textColor = nameTextColour
        nowTimeLabel.textColor = timeTextColour
        nowLineView.backgroundColor = nowLineColour
        
        sun = Sun(screenMinutes: screenMinutes, screenHeight: screenHeight, sunHeight: sunHeight, sunView: sunView, gradientLayer: gradientLayer, nowTimeLabel: nowTimeLabel)
        
        timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        
        setupPermissions()
        
        // Notifications
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(locationUpdate), name: Location.locationEvent, object: nil)
        
//        NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
//        hourSlider.hidden = true
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func setupPermissions() {
        pscope.addPermission(LocationWhileInUsePermission(),
                             message: "We rarely check your location but need it to calculate the suns position.")
        
        // Show dialog with callbacks
        pscope.show({ finished, results in
            print("got results \(results)")
            
//            Location.startLocationWatching()
            Location.checkLocation()
            }, cancelled: { (results) -> Void in
                print("thing was cancelled")
        })
    }
    
    func timerAction() {
        offset += 10 * 60
        if offset > 24 * 60 * 60 {
            offset = 0
        }
        
        hourSlider.value = offset
        update(offset)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func dateComponentsToString(d: NSDateComponents) -> String {
        return "\(d.hour):\(d.minute)"
    }
    
    func locationUpdate() {
        update()
    }
    
    func update(offset: Float = 0) {
        if let location = Location.getLocation() {
            sun.update(offset, location: location)
        }
    }
    
    @IBAction func hourSliderDidChange(sender: AnyObject) {
        update(hourSlider.value)
    }
    
}

