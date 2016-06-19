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

class SunViewController: UIViewController, TouchDownProtocol, UIGestureRecognizerDelegate, MenuProtocol {

    @IBOutlet weak var sunView: UIView!
    @IBOutlet weak var hourSlider: UISlider!
    var gradientLayer = CAGradientLayer()
    
    var backgroundView: UIView!
    
    @IBOutlet weak var nowTimeLabel: UILabel!
    @IBOutlet weak var nowLineView: UIView!
    @IBOutlet weak var nowLabel: UILabel!
    @IBOutlet weak var futureLabel: UILabel!
    @IBOutlet weak var pastLabel: UILabel!
    
    // You guessed it: users current coordinates
    var myLoc: CLLocationCoordinate2D!
    
    // All of the logic to compute gradients and suntimes
    var sun: Sun!
    
    // Main view in display we use to capture all touch events
    var touchDownView: TouchDownView!
    
    // The offset in minutes that we are from now
    var offset: Double = 0
    
    // The offset y transform that we are for rest position
    var offsetTranslation: Double = 0
    
    var timer = NSTimer()
    
    // How long the sun view has been free scrolling
    var animationTimer = NSTimer()
    
    // The date the timer started running
    var animationFireDate: NSDate!
    
    // Whether or not we are scrolling free form
    var scrolling = false
    
    // Whether or not we are touch panning
    var panning = false
    
    // Whether or not a touch down event stopped the free scrolling
    var animationStopped = false
    
    // Whether or not the user is allowed to touch pan
    var allowedPan = true
    
    // Whether or not the sun view is off from rest position
    var offNow = false
    
    // Whether or not the menu is out of position right now
    var isMenuOut = false
    
    // The duration we will free form for
    var scrollAnimationDuration: NSTimeInterval = 0
    
    // The duration the animation went for before it was stopped
    var stopAnimationDuration: Double = 0
    
    // The y transform before the free form scrolling started
    var transformBeforeAnimation: Double = 0
    
    // The y transform after the free form scrolling ended
    var transformAfterAnimation: Double = 0

    // TODO: Remove hardcoded free form scroll duration
    let SCROLL_DURATION: NSTimeInterval = 1.2
    
    // Duration to use when animation sun view fade
    let MenuFadeAnimationDuration: NSTimeInterval = 0.25
    
    // Background alpha of background overlay view when menu is out
    let MenuBackgroundAlpha: CGFloat = 0.4
    
    // Whether or not the sun view is fading due to the menu animating
    let menuAnimation = false
    
    // Are we currently animating the background in or out
    
    // Modal we use to get location permissions
    let pscope = PermissionScope()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
        
        setupBackgroundView()
        
        // Notifications
        
        Bus.subscribeEvent(.LocationUpdate, observer: self, selector: #selector(locationUpdate))
//        Bus.subscribeEvent(.MenuOut, observer: self, selector: #selector(menuOut))
//        Bus.subscribeEvent(.MenuIn, observer: self, selector: #selector(menuIn))
        Bus.subscribeEvent(.Foregrounded, observer: self, selector: #selector(scrollReset))
        
        setupPermissions()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        sunView.alpha = 0
        update()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        Bus.removeSubscriptions(self)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func setupBackgroundView() {
        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.blackColor()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.userInteractionEnabled = false
        backgroundView.alpha = 0
        
        view.addSubview(backgroundView)
        view.bringSubviewToFront(backgroundView)
        
        let horizontalContraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: ["view": backgroundView])
        let verticalContraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: ["view": backgroundView])
        NSLayoutConstraint.activateConstraints(horizontalContraints + verticalContraints)
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
    
    // Update all the views the with the time offset value
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
    
    func reset() {
        self.stopAnimationTimer()
        self.scrolling = false
        self.panning = false
        self.allowedPan = true
        self.offset = 0.0
        self.offsetTranslation = 0.0
    }
    
    // Menu
    
    func menuIn() {
        isMenuOut = false
    }
    
    func menuOut() {
        isMenuOut = true
    }
    
    func menuStartAnimatingIn() {
        UIView.animateWithDuration(MenuFadeAnimationDuration) {
            self.backgroundView.alpha = 0
            self.isMenuOut = false
        }
    }
    
    func menuIsIn() {
        backgroundView.alpha = 0
        isMenuOut = false
    }
    
    func menuStartAnimatingOut() {
        isMenuOut = true
        UIView.animateWithDuration(MenuFadeAnimationDuration) {
            self.backgroundView.alpha = self.MenuBackgroundAlpha
        }
    }
    
    func menuIsOut() {
        backgroundView.alpha = MenuBackgroundAlpha
        isMenuOut = true
    }
    
    func menuIsMoving(percent: Float) {
        let alpha = CGFloat(percent) * MenuBackgroundAlpha
        backgroundView.alpha = alpha
        isMenuOut = alpha != 0
    }
    
    // Touch and Dragging
    
    // constrain offset minutes and offset tranform within proper view bounds
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
    
    // Convert tranform y translation to minute offset and normalize
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
            if recognizer.locationInView(view).x < 40 || scrolling {
                allowedPan = false
            } else {
                panning = true
            }
        } else if (recognizer.state == .Changed) {
            if allowedPan && !isMenuOut && !scrolling {
                let transformBy = translation + offsetTranslation
                let offsetBy = offsetSeconds + offset
                let (newTransformBy, newOffsetBy) = normalizeOffsets(transformBy, offsetBy: offsetBy)
                
                self.sunView.transform = CGAffineTransformMakeTranslation(0, CGFloat(newTransformBy))
                sun.findNow(newOffsetBy)
            }
        } else if (recognizer.state == .Ended) {
            if allowedPan && !isMenuOut {
                offset += offsetSeconds
                offsetTranslation += translation
                (offsetTranslation, offset) = normalizeOffsets(offsetTranslation, offsetBy: offset)
                
                let velocity = Double(recognizer.velocityInView(view).y)
                if abs(velocity) > 12 {
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
                self.setTransformWhenStopped()
                self.animationStopped = false
        })
    }
    
    func doubleTap(recognizer: UITapGestureRecognizer) {
        scrollReset()
    }
    
    func setTransformWhenStopped() {
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
        animationStopped = true
        sunView.layer.removeAllAnimations()
        self.setTransformWhenStopped()
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

