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
    
    var momentumScroll: MomentumScroll!
    
    var offset: Float = 0
    var offsetTranslation: Float = 0
    
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
        
        // Gestures
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        sunView.addGestureRecognizer(doubleTapRecognizer)
        
        sunView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGesture)))
        
        momentumScroll = MomentumScroll(sunView: sunView)
        
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
    
    // Touch and Dragging
    
    func normalizeOffsets(transformBy: Float, offsetBy: Float) -> (Float, Float) {
        var newTransformBy = transformBy
        var newOffsetBy = offsetBy
        
        let halfHeight = sun.screenHeight / 2
        let halfSunHeight = sun.sunHeight / 2
        let neg = transformBy < 0
        if abs(transformBy) > halfSunHeight - halfHeight {
            newTransformBy = halfSunHeight - halfHeight
            newOffsetBy = sun.pointsToMinutes(transformBy)
            
            newTransformBy = neg ? newTransformBy * -1 : newTransformBy
            newOffsetBy = neg ? newOffsetBy * -1 : newOffsetBy
        }
        return (newTransformBy, newOffsetBy)
    }
    
    func panGesture(recognizer: UIPanGestureRecognizer) {
        let translation = Float(recognizer.translationInView(view).y)
        let offsetMinutes = sun.pointsToMinutes(translation)
        let offsetSeconds = offsetMinutes * 60
        
        if (recognizer.state == .Began) {
            
        } else if (recognizer.state == .Changed) {
            
            let transformBy = translation + offsetTranslation
            let offsetBy = offsetSeconds + offset
            
            let (newTransformBy, newOffsetBy) = normalizeOffsets(transformBy, offsetBy: offsetBy)
            
            sunView.transform = CGAffineTransformMakeTranslation(0, CGFloat(newTransformBy))
            sun.findNow(newOffsetBy)
        } else if (recognizer.state == .Ended) {
            offset += offsetSeconds
            offsetTranslation += translation
            (offsetTranslation, offset) = normalizeOffsets(offsetTranslation, offsetBy: offset)
        }
    }
    
    func doubleTap(recognizer: UITapGestureRecognizer) {
        UIView.animateWithDuration(1, delay: 0, options: .CurveEaseInOut, animations: {
            self.sunView.transform = CGAffineTransformMakeTranslation(0, 0)
            }, completion: {finished in
                self.offset = 0
                self.offsetTranslation = 0
                self.sun.findNow(self.offset)
        })
    }
    
}

