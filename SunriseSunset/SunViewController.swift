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

class SunViewController: UIViewController, TouchDownProtocol, UIGestureRecognizerDelegate {

    @IBOutlet weak var sunView: UIView!
    @IBOutlet weak var hourSlider: UISlider!
    var gradientLayer = CAGradientLayer()
    
    @IBOutlet weak var nowTimeLabel: UILabel!
    @IBOutlet weak var nowLineView: UIView!
    @IBOutlet weak var nowLabel: UILabel!
    @IBOutlet weak var futureLabel: UILabel!
    @IBOutlet weak var pastLabel: UILabel!
    
    var myLoc: CLLocationCoordinate2D!
    
    var sun: Sun!
    var touchDownView: TouchDownView!
    
    var offset: Double = 0
    var offsetTranslation: Double = 0
    
    var timer = NSTimer()
    
    var animationTimer = NSTimer()
    var animationFireDate: NSDate!
    var scrolling = false
    var panning = false
    var animationStopped = false
    var allowedPan = true
    var offNow = false
    var isMenuOut = false
    var scrollAnimationDuration: NSTimeInterval = 0
    var stopAnimationDuration: Double = 0
    var transformBeforeAnimation: Double = 0
    var transformAfterAnimation: Double = 0
    var transformWhenStopped: Double = 0
    let SCROLL_DURATION: NSTimeInterval = 1.2
    
    let pscope = PermissionScope()
    
    var menuViewController: MenuViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        Sun.timeFormatter.timeZone = NSTimeZone.localTimeZone()
        
        let screenMinutes = Float(6 * 60)
        let screenHeight = Float(view.frame.height)
        let sunHeight = Float(sunView.frame.height)
        
        touchDownView = view as! TouchDownView
        touchDownView.delegate = self
        
        sunView.layer.addSublayer(gradientLayer)
        
        nowLabel.textColor = nameTextColour
        nowLabel.font = fontTwilight
        nowTimeLabel.textColor = timeTextColour
        nowTimeLabel.font = fontDetail
        nowLineView.backgroundColor = nowLineColour
        
        nowLabel.addSimpleShadow()
        nowTimeLabel.addSimpleShadow()
        pastLabel.addSimpleShadow()
        futureLabel.addSimpleShadow()
        
        sun = Sun(screenMinutes: screenMinutes, screenHeight: screenHeight, sunHeight: sunHeight, sunView: sunView, gradientLayer: gradientLayer, nowTimeLabel: nowTimeLabel)
        
        // Gestures
        
        // Double tap
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        sunView.addGestureRecognizer(doubleTapRecognizer)
        
        // Pan (scrolling)
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        panRecognizer.delegate = self
        sunView.addGestureRecognizer(panRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        sunView.addGestureRecognizer(tapRecognizer)
        
        // Update every minute
        timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        
        // Notifications
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(locationUpdate), name: Location.locationEvent, object: nil)
        Bus.subscribeEvent(.MenuOut, observer: self, selector: #selector(menuOut))
        Bus.subscribeEvent(.MenuIn, observer: self, selector: #selector(menuIn))
        Bus.subscribeEvent(.Foregrounded, observer: self, selector: #selector(scrollReset))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        sunView.alpha = 0
        update()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        setupPermissions()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        Bus.removeSubscriptions(self)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func menuIn() {
        isMenuOut = false
    }
    
    func menuOut() {
        isMenuOut = true
    }
    
    func startAnimationTimer() {
        animationTimer = NSTimer.scheduledTimerWithTimeInterval(0.06, target: self, selector: #selector(animationUpdate), userInfo: nil, repeats: true)
        animationFireDate = NSDate()
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
    
    func update(offset: Double = 0) {
        if !scrolling && !panning && !offNow {
            if let location = Location.getLocation() {
                sun.update(offset, location: location)
                
                // Fade in sun view if not already visible
                if self.sunView.alpha == 0 {
                    UIView.animateWithDuration(0.5) {
                        self.sunView.alpha = 1
                    }
                }
            }
        }
        offNow = Int(floor(offset)) != 0
    }
    
    @IBAction func hourSliderDidChange(sender: AnyObject) {
        update(Double(hourSlider.value))
    }
    
    // Touch and Dragging
    
    func normalizeOffsets(transformBy: Double, offsetBy: Double) -> (Double, Double) {
        var newTransformBy = transformBy
        var newOffsetBy = offsetBy
        
        let halfHeight = Double(sun.screenHeight) / 2
        let halfSunHeight = Double(sun.sunHeight) / 2
        let neg = transformBy < 0
        if abs(transformBy) > halfSunHeight - halfHeight {
            newTransformBy = halfSunHeight - halfHeight
            newOffsetBy = sun.pointsToMinutes(transformBy)
            
            newTransformBy = neg ? newTransformBy * -1 : newTransformBy
            newOffsetBy = neg ? newOffsetBy * -1 : newOffsetBy
        }
        return (newTransformBy, newOffsetBy)
    }
    
    func setOffsetFromTranslation(translation: Double) {
        offsetTranslation = translation
        offset = sun.pointsToMinutes(offsetTranslation)
        (offsetTranslation, offset) = normalizeOffsets(offsetTranslation, offsetBy: offset)
    }
    
    func panGesture(recognizer: UIPanGestureRecognizer) {
        let translation = Double(recognizer.translationInView(view).y)
        let offsetMinutes = sun.pointsToMinutes(translation)
        let offsetSeconds = offsetMinutes
        
        if (recognizer.state == .Began) {
            if recognizer.locationInView(view).x < 40 {
                allowedPan = false
            } else {
                panning = true
            }
        } else if (recognizer.state == .Changed) {
            if allowedPan && !isMenuOut {
                let transformBy = translation + offsetTranslation
                let offsetBy = offsetSeconds + offset
                let (newTransformBy, newOffsetBy) = normalizeOffsets(transformBy, offsetBy: offsetBy)
                
                sunView.transform = CGAffineTransformMakeTranslation(0, CGFloat(newTransformBy))
                sun.findNow(newOffsetBy)
            }
        } else if (recognizer.state == .Ended) {
            if allowedPan && !isMenuOut {
                offset += offsetSeconds
                offsetTranslation += translation
                (offsetTranslation, offset) = normalizeOffsets(offsetTranslation, offsetBy: offset)
                
                let velocity = Double(recognizer.velocityInView(view).y)
                if abs(velocity) > 8 {
                    animateScroll(velocity * 0.55)
                }
            }
            panning = false
            allowedPan = true
        }
    }
    
    func animateScroll(velocity: Double) {
        transformAfterAnimation = offsetTranslation + velocity
        (transformAfterAnimation, _) = normalizeOffsets(transformAfterAnimation, offsetBy: 0)
        
        startAnimationTimer()
        transformBeforeAnimation = Double(sunView.transform.ty)
        
        // TODO: Make scroll duration dynamic
        scrollAnimationDuration = SCROLL_DURATION
        scrolling = true
        
        UIView.animateWithDuration(scrollAnimationDuration, delay: 0, options: [.AllowUserInteraction, .BeginFromCurrentState], animations: {
            self.sunView.setEasingFunction(Easing.easeOutQuad, forKeyPath: "transform")
            self.sunView.transform = CGAffineTransformMakeTranslation(0, CGFloat(self.transformAfterAnimation))
            }, completion: {finished in
                self.stopAnimationTimer()
                self.scrolling = false
                self.sunView.removeEasingFunctionForKeyPath("transform")
                
                let transformDifference = self.transformAfterAnimation - self.transformBeforeAnimation
                let animationDuration = abs(self.animationFireDate.timeIntervalSinceNow) + (1 / 60) // <- this magic number makes view not jump as much when scroll stopping
                
                self.offsetTranslation = Easing.easeOutQuadFunc(animationDuration, startValue: self.transformBeforeAnimation, changeInValue: transformDifference, duration: self.scrollAnimationDuration)

                if (!self.animationStopped) {
                    self.offsetTranslation = self.transformAfterAnimation
                }
                
                self.setOffsetFromTranslation(self.offsetTranslation)
                self.sun.findNow(self.offset)
                self.sunView.transform = CGAffineTransformMakeTranslation(0, CGFloat(self.offsetTranslation))
                
                self.animationStopped = false
        })
    }
    
    func doubleTap(recognizer: UITapGestureRecognizer) {
        scrollReset()
    }
    
    func reset() {
        self.stopAnimationTimer()
        self.scrolling = false
        self.panning = false
        self.allowedPan = true
        self.offset = 0.0
        self.offsetTranslation = 0.0
    }
    
    func scrollReset() {
        transformBeforeAnimation = Double(sunView.transform.ty)
        transformAfterAnimation = 0.0
        scrollAnimationDuration = SCROLL_DURATION
        startAnimationTimer()
        scrolling = true
        UIView.animateWithDuration(scrollAnimationDuration, animations: {
            self.sunView.setEasingFunction(Easing.easeOutQuad, forKeyPath: "transform")
            self.sunView.transform = CGAffineTransformMakeTranslation(0, 0)
            }, completion: { finished in
                self.sunView.removeEasingFunctionForKeyPath("transform")
                self.reset()
                self.update(self.offset)
        })
    }
    
    func stopScroll() {
        scrolling = false
        animationStopped = true
        sunView.layer.removeAllAnimations()
    }
    
    func animationUpdate() {
        let transformDifference = self.transformAfterAnimation - self.transformBeforeAnimation
        let ease = Easing.easeOutQuadFunc(animationFireDate.timeIntervalSinceNow * -1, startValue: transformBeforeAnimation, changeInValue: transformDifference, duration:scrollAnimationDuration)
//        print("d: \(animationFireDate.timeIntervalSinceNow * -1) b: \(transformBeforeAnimation) a: \(transformAfterAnimation) ease: \(ease)")
        
        sun.findNow(sun.pointsToMinutes(ease))
    }
    
    func tapGesture(recognizer: UITapGestureRecognizer) {
        Bus.sendMessage(.SendMenuIn, data: nil)
    }
    
    func touchDown(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if scrolling {
            stopScroll()
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

