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

class SunViewController: UIViewController, TouchDownProtocol {

    @IBOutlet weak var sunView: UIView!
    @IBOutlet weak var hourSlider: UISlider!
    var gradientLayer = CAGradientLayer()
    
    @IBOutlet weak var nowTimeLabel: UILabel!
    @IBOutlet weak var nowLineView: UIView!
    @IBOutlet weak var nowLabel: UILabel!
    
    @IBOutlet weak var menuContainerView: UIView!
    @IBOutlet weak var menuLeadingConstraint: NSLayoutConstraint!
    
    var myLoc: CLLocationCoordinate2D!
    
    var sun: Sun!
    var touchDownView: TouchDownView!
    
    var offset: Double = 0
    var offsetTranslation: Double = 0
    
    var timer = NSTimer()
    
    var animationTimer = NSTimer()
    var animationFireDate: NSDate!
    var scrolling = false
    var animationStopped = false
    var scrollAnimationDuration: NSTimeInterval = 0
    var stopAnimationDuration: Double = 0
    var transformBeforeAnimation: Double = 0
    var transformAfterAnimation: Double = 0
    var transformWhenStopped: Double = 0
    let SCROLL_DURATION: NSTimeInterval = 1
    
    let pscope = PermissionScope()
    
    var menuViewController: MenuViewController!
    
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
        
        // Menu
        menuHardIn()
        
        // Gestures
        
        // Double tap
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        sunView.addGestureRecognizer(doubleTapRecognizer)
        
        // Pan (scrolling)
        sunView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGesture)))
        timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        
        // Side Menu (edge swipe)
        let menuRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(sideSwipe))
        menuRecognizer.edges = .Left
        view.addGestureRecognizer(menuRecognizer)
        
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "MenuSegue" {
            menuViewController = segue.destinationViewController as! MenuViewController
        }
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
    
    func timerAction() {
        offset += 10 * 60
        if offset > 24 * 60 * 60 {
            offset = 0
        }
        
        hourSlider.value = Float(offset)
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
    
    func update(offset: Double = 0) {
        if let location = Location.getLocation() {
            sun.update(offset, location: location)
        }
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
        } else if (recognizer.state == .Changed) {
            let transformBy = translation + offsetTranslation
            let offsetBy = offsetSeconds + offset
            let (newTransformBy, newOffsetBy) = normalizeOffsets(transformBy, offsetBy: offsetBy)
            
            sunView.transform = CGAffineTransformMakeTranslation(0, CGFloat(newTransformBy))
//            print("pan transform: \(newTransformBy)")
            sun.findNow(newOffsetBy)
        } else if (recognizer.state == .Ended) {
            offset += offsetSeconds
            offsetTranslation += translation
            (offsetTranslation, offset) = normalizeOffsets(offsetTranslation, offsetBy: offset)
            
            let velocity = Double(recognizer.velocityInView(view).y)
            if abs(velocity) > 5 {
                animateScroll(velocity)
            }
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
    
    // TODO: Animate now label when this changes
    func doubleTap(recognizer: UITapGestureRecognizer) {
        transformBeforeAnimation = Double(sunView.transform.ty)
        transformAfterAnimation = 0.0
        scrollAnimationDuration = SCROLL_DURATION
        startAnimationTimer()
        UIView.animateWithDuration(scrollAnimationDuration, animations: {
            self.sunView.setEasingFunction(Easing.easeOutQuad, forKeyPath: "transform")
            self.sunView.transform = CGAffineTransformMakeTranslation(0, 0)
            }, completion: { finished in
                self.stopAnimationTimer()
                self.offset = 0.0
                self.offsetTranslation = 0.0
                self.sun.findNow(self.offset)
                
                self.sunView.removeEasingFunctionForKeyPath("transform")
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
    
    func touchDown(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if scrolling {
            stopScroll()
        }
    }
    
    // Side Menu
    
    func menuHardIn() {
        let menuWidth = menuContainerView.frame.width
        menuLeadingConstraint.constant = -menuWidth
    }
    
    func sideSwipe(recognizer: UIScreenEdgePanGestureRecognizer) {
        let menuWidth = menuContainerView.frame.width
        let fingerX = recognizer.locationInView(view).x
        let adjustedX = fingerX > menuWidth ? menuWidth : fingerX
        let menuTransform = -menuWidth + adjustedX
        
        print("\n")
        print("x: \(fingerX)")
        print("transform: \(menuTransform)")
        menuLeadingConstraint.constant = menuTransform
        
        print(recognizer.state)
    }
    
}

