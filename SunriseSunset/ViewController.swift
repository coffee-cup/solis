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

class ViewController: UIViewController {

    @IBOutlet weak var sunView: UIView!
    @IBOutlet weak var hourSlider: UISlider!
    var gradientLayer = CAGradientLayer()
    
    var myLoc: CLLocationCoordinate2D!
    
    var sun: Sun!
    
    var offset: Float = 0
    var timer = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let screenMinutes = Float(6 * 60)
        let screenHeight = Float(view.frame.height)
        let sunHeight = Float(sunView.frame.height)
        let sunViewScale = Float(Float(sunHeight) / Float(screenHeight))
        
        sunView.layer.addSublayer(gradientLayer)
        
        let lat: CLLocationDegrees = 49.2755480
        let lon: CLLocationDegrees = -123.1153840
        myLoc = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        sun = Sun(screenMinutes: screenMinutes, screenHeight: screenHeight, sunHeight: sunHeight, sunViewScale: sunViewScale, sunView: sunView, gradientLayer: gradientLayer)
        
        update()

        timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func timerAction() {
        offset += 10 * 60
        if offset > 24 * 60 * 60 {
            offset = 0
        }
        
        hourSlider.value = offset
        sun.update(offset, location: myLoc)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func dateComponentsToString(d: NSDateComponents) -> String {
        return "\(d.hour):\(d.minute)"
    }
    
    func update() {
        sun.update(0, location: myLoc)
    }
    
    @IBAction func hourSliderDidChange(sender: AnyObject) {
        sun.update(hourSlider.value, location: myLoc)
    }
    
}

