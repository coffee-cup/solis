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
import UIView_Easing

class ViewController: UIViewController, TouchDownProtocol {

    @IBOutlet weak var sunView: UIView!
    @IBOutlet weak var hourSlider: UISlider!
    var gradientLayer = CAGradientLayer()
    
    @IBOutlet weak var nowTimeLabel: UILabel!
    @IBOutlet weak var nowLineView: UIView!
    @IBOutlet weak var nowLabel: UILabel!
    
    var myLoc: CLLocationCoordinate2D!
    
    var sun: Sun!
    var touchDownView: TouchDownView!
    
    var offset: Float = 0
    var offsetTranslation: Float = 0
    
    var timer = NSTimer()
    
    var animationTimer = NSTimer()
    var animationFireDate: NSDate!
    var scrolling = false
    var animationStopped = false
    var scrollAnimationDuration: NSTimeInterval = 0
    var stopAnimationDuration: Float = 0
    var transformBeforeAnimation: Float = 0
    var transformAfterAnimation: Float = 0
    var transformWhenStopped: CGFloat = 0
    let SCROLL_DURATION: NSTimeInterval = 1
    
    let pscope = PermissionScope()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        Sun.timeFormatter.dateFormat = "HH:mm"
        
        let screenMinutes = Float(6 * 60)
        let screenHeight = Float(view.frame.height)
        let sunHeight = Float(sunView.frame.height)
        
        touchDownView = view as! TouchDownView
        touchDownView.delegate = self
        
        sunView.layer.addSublayer(gradientLayer)
        
        nowLabel.textColor = nameTextColour
        nowTimeLabel.textColor = timeTextColour
        nowLineView.backgroundColor = nowLineColour
        
        sun = Sun(screenMinutes: screenMinutes, screenHeight: screenHeight, sunHeight: sunHeight, sunView: sunView, gradientLayer: gradientLayer, nowTimeLabel: nowTimeLabel)
        
        // Gestures
        
        // Double tap
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        sunView.addGestureRecognizer(doubleTapRecognizer)
        
        // Pan (scrolling)
        sunView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGesture)))
        timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        
        setupPermissions()
        
        // Notifications
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(locationUpdate), name: Location.locationEvent, object: nil)
        
//        NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
//        hourSlider.hidden = true
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func startAnimationTimer() {
        animationTimer = NSTimer.scheduledTimerWithTimeInterval(0.06, target: self, selector: #selector(animationUpdate), userInfo: nil, repeats: true)
    }
    
    func stopAnimationTimer() {
        animationTimer.invalidate()
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
    
    func setOffsetFromTranslation(translation: Float) {
        offsetTranslation = translation
        offset = sun.pointsToMinutes(offsetTranslation)
        (offsetTranslation, offset) = normalizeOffsets(offsetTranslation, offsetBy: offset)
    }
    
    func panGesture(recognizer: UIPanGestureRecognizer) {
        let translation = Float(recognizer.translationInView(view).y)
        let offsetMinutes = sun.pointsToMinutes(translation)
        let offsetSeconds = offsetMinutes
        
        if (recognizer.state == .Began) {
//            print("begain pan")
        } else if (recognizer.state == .Changed) {
            
            let transformBy = translation + offsetTranslation
            let offsetBy = offsetSeconds + offset
            
            let (newTransformBy, newOffsetBy) = normalizeOffsets(transformBy, offsetBy: offsetBy)
            
            sunView.transform = CGAffineTransformMakeTranslation(0, CGFloat(newTransformBy))
            print("pan offset: \(newOffsetBy)")
            sun.findNow(newOffsetBy)
        } else if (recognizer.state == .Ended) {
            offset += offsetSeconds
            offsetTranslation += translation
            (offsetTranslation, offset) = normalizeOffsets(offsetTranslation, offsetBy: offset)
            
            let velocity = recognizer.velocityInView(view).y
            if abs(velocity) > 5 {
                animateScroll(Float(velocity))
            }
        }
    }
    
    func animateScroll(velocity: Float) {
        transformAfterAnimation = offsetTranslation + velocity
        (transformAfterAnimation, _) = normalizeOffsets(transformAfterAnimation, offsetBy: 0)
        
        startAnimationTimer()
        transformBeforeAnimation = Float(sunView.transform.ty)
        animationFireDate = NSDate()
        
        print("\nvelocity: \(velocity)")
        print("initial transform \(transformBeforeAnimation)")
        print("setting transform to \(transformAfterAnimation)")
        
        scrollAnimationDuration = 2
        
        scrolling = true
        
        UIView.animateWithDuration(scrollAnimationDuration, delay: 0, options: [.AllowUserInteraction, .BeginFromCurrentState], animations: {
            self.sunView.setEasingFunction(Easing.easeOutQuad, forKeyPath: "transform")
            self.sunView.transform = CGAffineTransformMakeTranslation(0, CGFloat(self.transformAfterAnimation))
            }, completion: {finished in
                self.stopAnimationTimer()
                self.scrolling = false
                self.sunView.removeEasingFunctionForKeyPath("transform")
                
//                let transformDifference = Float(self.transformAfterAnimation - self.transformBeforeAnimation)
//                let timeScale = animationDuration / Float(self.scrollAnimationDuration)
//                let animationDuration = Float(abs(self.animationFireDate.timeIntervalSinceNow))
                
                print("time: \(self.animationFireDate.timeIntervalSinceNow)")
                
//                self.offsetTranslation = Easing.easeOutQuadFunc(animationDuration, startValue: Float(self.transformBeforeAnimation), changeInValue: transformDifference, duration: Float(self.scrollAnimationDuration))
//                self.offsetTranslation = Float(self.transformBeforeAnimation) + (transformDifference * timeScale)
                print("end ease: \(self.offsetTranslation)")
                
                if (self.animationStopped) {
                    self.offsetTranslation = Float(self.transformWhenStopped)
                } else {
                    self.offsetTranslation = Float(self.transformAfterAnimation)
                }
                
                self.setOffsetFromTranslation(self.offsetTranslation)
                
                self.sunView.transform = CGAffineTransformMakeTranslation(0, CGFloat(self.offsetTranslation))
                
                print("offset: \(self.offset)")
                self.sun.findNow(self.offset)
                
                self.animationStopped = false
        })
        
//        let animationPoints: ViewEasingFunctionPointerType = BounceEaseIn
//        UIView.animateWithDuration(scrollAnimationDuration, animations: {
//            self.sunView.setEasingFunction(, forKeyPath: "transform")
//        })
    }
    
    func doubleTap(recognizer: UITapGestureRecognizer) {
        UIView.animateWithDuration(SCROLL_DURATION, delay: 0, options: .CurveEaseInOut, animations: {
            self.sunView.transform = CGAffineTransformMakeTranslation(0, 0)
            }, completion: {finished in
                self.offset = 0
                self.offsetTranslation = 0
                self.sun.findNow(self.offset)
        })
    }
    
    // TODO: Change ease function to return and use Doubles
    
    func stopScroll() {
        scrolling = false
        animationStopped = true
        print("stop time: \(self.animationFireDate.timeIntervalSinceNow)")
        stopAnimationDuration = Float(animationFireDate.timeIntervalSinceNow)
        let transformDifference = Float(self.transformAfterAnimation - self.transformBeforeAnimation)
        let ease = Easing.easeOutQuadFunc(Float(self.animationFireDate.timeIntervalSinceNow * -1), startValue: Float(self.transformBeforeAnimation), changeInValue: transformDifference, duration: Float(self.scrollAnimationDuration))
        transformWhenStopped = CGFloat(ease)
        print("stop ease: \(ease)")
        
        self.sunView.transform = CGAffineTransformMakeTranslation(0, CGFloat(ease))
        sunView.layer.removeAllAnimations()
    }
    
    func animationUpdate() {
        let transformDifference = Float(self.transformAfterAnimation - self.transformBeforeAnimation)
        let ease = Easing.easeOutQuadFunc(Float(animationFireDate.timeIntervalSinceNow * -1), startValue: Float(transformBeforeAnimation), changeInValue: transformDifference, duration: 2)
//        transformWhenStopped = CGFloat(ease)
        print("\nd: \(animationFireDate.timeIntervalSinceNow) b: \(transformBeforeAnimation) a: \(transformAfterAnimation) ease: \(ease)")
        
        sun.findNow(sun.pointsToMinutes(ease))
    }
    
    func touchDown(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if scrolling {
            stopAnimationTimer()
            stopScroll()
        }
    }
    
}

