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
import UIView_Easing
import SPPermission

class SunViewController: UIViewController, TouchDownProtocol, UIGestureRecognizerDelegate, MenuProtocol, SunProtocol {

    @IBOutlet weak var sunView: UIView!
    @IBOutlet weak var hourSlider: UISlider!
    var gradientLayer = CAGradientLayer()
    
    var backgroundView: UIView!
    
    @IBOutlet weak var nowView: UIView!
    @IBOutlet weak var nowTimeLabel: UILabel!
    @IBOutlet weak var nowLineView: UIView!
    @IBOutlet weak var nowLabel: UILabel!
    @IBOutlet weak var nowLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var futureLabel: UILabel!
    @IBOutlet weak var pastLabel: UILabel!
    
    @IBOutlet weak var noLocationLabel1: SpringLabel!
    @IBOutlet weak var noLocationLabel2: SpringLabel!
    
    @IBOutlet weak var centerImageView: SpringImageView!
    @IBOutlet weak var centerButton: UIButton!
    
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
    
    var timer = Timer()
    
    // How long the sun view has been free scrolling
    var animationTimer = Timer()
    
    // The date the timer started running
    var animationFireDate: Date!
    
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
    
    // Whether or not the now line is colliding with a sun line
    var colliding = false
    
    // Whether we have a location to render a gradient with
    var gotLocation = false
    
    // Flag indicating the location just changed
    var locationJustChanged = false
    
    // The duration we will free form for
    var scrollAnimationDuration: TimeInterval = 0
    
    // The duration the animation went for before it was stopped
    var stopAnimationDuration: Double = 0
    
    // The y transform before the free form scrolling started
    var transformBeforeAnimation: Double = 0
    
    // The y transform after the free form scrolling ended
    var transformAfterAnimation: Double = 0

    // TODO: Remove hardcoded free form scroll duration
    let SCROLL_DURATION: TimeInterval = 1.2
    
    // Duration to use when animation sun view fade
    let MenuFadeAnimationDuration: TimeInterval = 0.25
    
    // Background alpha of background overlay view when menu is out
    let MenuBackgroundAlpha: CGFloat = 0.4
    
    // Whether or not the sun view is fading due to the menu animating
    let menuAnimation = false
    
    // How large the sun view is compared to the normal view
    let SunViewScreenMultiplier: CGFloat = 9
    
    // Modal we use to get location permissions
//    let pscope = PermissionScope()
    
    var smoothyOffset: Double = 0
    var smoothyForward = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let screenMinutes = Float(60 * 6) // 6 hours / screen height
        let screenHeight = Float(view.frame.height)
        let sunHeight = screenHeight * Float(SunViewScreenMultiplier)
        
        sunView.translatesAutoresizingMaskIntoConstraints = true
        sunView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: CGFloat(sunHeight))
        sunView.center = view.center
        
        touchDownView = view as? TouchDownView
        touchDownView.delegate = self
        
        touchDownView.backgroundColor = nauticalColour
        gradientLayer.backgroundColor = nauticalColour.cgColor
        sunView.layer.addSublayer(gradientLayer)
        
        nowLabel.textColor = nameTextColour
        nowLabel.font = fontTwilight
        nowTimeLabel.textColor = timeTextColour
        nowTimeLabel.font = fontDetail
        nowLineView.backgroundColor = nowLineColour
        nowLineView.isUserInteractionEnabled = false
        
        nowLabel.addSimpleShadow()
        nowTimeLabel.addSimpleShadow()
        pastLabel.addSimpleShadow()
        futureLabel.addSimpleShadow()
        
        centerButton.isEnabled = false
        centerImageView.duration = CGFloat(1)
        centerImageView.curve = "easeInOut"
        centerImageView.alpha = 0
        
        noLocationLabel1.alpha = 0
        noLocationLabel2.alpha = 0
        
        sun = Sun(screenMinutes: screenMinutes,
                  screenHeight: screenHeight,
                  sunHeight: sunHeight,
                  sunView: sunView,
                  gradientLayer: gradientLayer,
                  nowTimeLabel: nowTimeLabel,
                  nowLabel: nowLabel)
        sun.delegate = self
        
        // Gestures
        
        // Double tap
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        sunView.addGestureRecognizer(doubleTapRecognizer)
        
        // Pan (scrolling)
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        panRecognizer.delegate = self
        sunView.addGestureRecognizer(panRecognizer)
        
        // Send Menu in tap
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        sunView.addGestureRecognizer(tapRecognizer)
        
        // Long press tap (toggle sun areas)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture))
        longPressRecognizer.allowableMovement = 0.5
        longPressRecognizer.minimumPressDuration = 0.5
        sunView.addGestureRecognizer(longPressRecognizer)
        
        setupBackgroundView()
        
        // Notifications
        
        Bus.subscribeEvent(.locationUpdate, observer: self, selector: #selector(locationUpdate))
        Bus.subscribeEvent(.locationChanged, observer: self, selector: #selector(locationChanged))
        Bus.subscribeEvent(.gotTimeZone, observer: self, selector: #selector(timeZoneUpdate))
        Bus.subscribeEvent(.foregrounded, observer: self, selector: #selector(scrollReset))
        
        setupPermissions()
        
        reset()
        scrollReset()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sunView.alpha = 0
        update()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Update every minute
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        Bus.removeSubscriptions(self)
    }
    
    func setupBackgroundView() {
        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.black
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.isUserInteractionEnabled = false
        backgroundView.alpha = 0
        
        view.addSubview(backgroundView)
        view.bringSubviewToFront(backgroundView)
        
        let horizontalContraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view": backgroundView!])
        let verticalContraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": backgroundView!])
        NSLayoutConstraint.activate(horizontalContraints + verticalContraints)
    }
    
    func startAnimationTimer() {
        animationTimer = Timer.scheduledTimer(timeInterval: 0.06, target: self, selector: #selector(animationUpdate), userInfo: nil, repeats: true)
        animationFireDate = Date()
    }
    
    func stopAnimationTimer() {
        animationTimer.invalidate()
    }
    
    func setupPermissions() {
        if SPPermission.isAllowed(.locationWhenInUse) {
            SunLocation.checkLocation()
        } else {
            SPPermission.request(.locationWhenInUse, with: {
              print("test")
            })
        }
        
//        pscope.style()
//        pscope.addPermission(LocationWhileInUsePermission(),
//                             message: "We rarely check your location but need it to calculate the suns position")
//        
//        // Show dialog with callbacks
//        pscope.show({ finished, results in
//            if results[0].status == PermissionStatus.authorized {
//                print("got results \(results)")
//                
////                SunLocation.startLocationWatching()
//                SunLocation.checkLocation()
//            }
//            }, cancelled: { (results) -> Void in
//                print("Location permission was cancelled")
//        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func dateComponentsToString(_ d: DateComponents) -> String {
        return "\(String(describing: d.hour)):\(String(describing: d.minute))"
    }
    
    @objc func timeZoneUpdate() {
        update()
    }
    
    @objc func locationUpdate() {
        print("location update")
        update()
    }
    
    @objc func locationChanged() {
        print("location changed")
        locationJustChanged = true
//        scrollReset()
    }
    
    // Enable=true means we are showing the no location views
    func noLocationViews(_ enable: Bool) {
        if !gotLocation {
            // Do not re-animate if already showing
            if enable && noLocationLabel1.alpha == 1 {
                return
            } else if !enable && noLocationLabel1.alpha == 0 {
                return
            }

            UIView.animate(withDuration: 0.5) {
                self.noLocationLabel1.alpha = enable ? 1 : 0
                self.noLocationLabel2.alpha = enable ? 1 : 0
                self.nowView.alpha = !enable ? 1 : 0
            }
        }
    }
    
    // Update all the views the with the time offset value
    @objc func update() {
        if (!scrolling && !panning && !offNow) || locationJustChanged {
            if let location = SunLocation.getLocation() {
                sun.update(offset, location: location)
                
                // Fade in sun view if not already visible
                if self.sunView.alpha == 0 {
                    UIView.animate(withDuration: 0.5) {
                        self.sunView.alpha = 1
                    }
                }
                
                // If we are updating right from changing location
                // reset the scroll
                if locationJustChanged {
                    locationJustChanged = false
                    scrollReset()
                }
                
                noLocationViews(false)
                gotLocation = true
            } else {
                noLocationViews(true)
            }
        }
        offNow = Int(floor(offset)) != 0
        setCenterButton()
    }
    
    // Update from transformation move
    // Do not update maths of sunlines
    func moveUpdate(_ offset: Double = 0) {
        offNow = Int(floor(abs(offset))) != 0
        sun.findNow(offNow ? offset : 0)
        setCenterButton()
    }
    
    func setCenterButton() {
        if offNow && !centerButton.isEnabled {
            centerButton.isEnabled = true
            centerImageView.animation = "fadeIn"
            centerImageView.animate()
        } else if !offNow && centerButton.isEnabled {
            centerButton.isEnabled = false
            centerImageView.animation = "fadeOut"
            centerImageView.animate()
        }
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
        UIView.animate(withDuration: MenuFadeAnimationDuration) {
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
        UIView.animate(withDuration: MenuFadeAnimationDuration) {
            self.backgroundView.alpha = self.MenuBackgroundAlpha
        }
    }
    
    func menuIsOut() {
        backgroundView.alpha = MenuBackgroundAlpha
        isMenuOut = true
    }
    
    func menuIsMoving(_ percent: Float) {
        let alpha = CGFloat(percent) * MenuBackgroundAlpha
        backgroundView.alpha = alpha
        isMenuOut = alpha != 0
    }
    
    // Touch and Dragging
    
    // constrain offset minutes and offset tranform within proper view bounds
    func normalizeOffsets(_ transformBy: Double, offsetBy: Double) -> (Double, Double) {
        var newTransformBy = transformBy
        var newOffsetBy = offsetBy
        let ViewPadding: Double = 0
        
        let halfHeight = Double(sun.screenHeight) / 2
        let halfSunHeight = Double(sun.sunHeight) / 2
        let neg = transformBy < 0
        if abs(transformBy) > halfSunHeight - halfHeight - ViewPadding {
            newTransformBy = halfSunHeight - halfHeight - ViewPadding
            newOffsetBy = sun.pointsToMinutes(transformBy)
            
            newTransformBy = neg ? newTransformBy * -1 : newTransformBy
            newOffsetBy = neg ? newOffsetBy * -1 : newOffsetBy
        }
        return (newTransformBy, newOffsetBy)
    }
    
    // Convert tranform y translation to minute offset and normalize
    func setOffsetFromTranslation(_ translation: Double) {
        offsetTranslation = translation
        offset = sun.pointsToMinutes(offsetTranslation)
        (offsetTranslation, offset) = normalizeOffsets(offsetTranslation, offsetBy: offset)
    }
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = Double(recognizer.translation(in: view).y)
        let offsetMinutes = sun.pointsToMinutes(translation)
        let offsetSeconds = offsetMinutes
        
        if (recognizer.state == .began) {
            if recognizer.location(in: view).x < 40 || scrolling { // 40 so pan gestures don't interfer with pulling menu out
                allowedPan = false
            } else {
                panning = true
            }
        } else if (recognizer.state == .changed) {
            if allowedPan && !isMenuOut && !scrolling {
                let transformBy = translation + offsetTranslation
                let offsetBy = offsetSeconds + offset
                let (newTransformBy, newOffsetBy) = normalizeOffsets(transformBy, offsetBy: offsetBy)
                
                self.sunView.transform = CGAffineTransform(translationX: 0, y: CGFloat(newTransformBy))
                moveUpdate(newOffsetBy)
            }
        } else if (recognizer.state == .ended) {
            if allowedPan && !isMenuOut {
                offset += offsetSeconds
                offsetTranslation += translation
                (offsetTranslation, offset) = normalizeOffsets(offsetTranslation, offsetBy: offset)
                
                let velocity = Double(recognizer.velocity(in: view).y)
                if abs(velocity) > 12 { // 12 so scroll doesn't animate for soft pans
                    animateScroll(velocity * 0.55) // 0.55 to weaken momentum scoll velocity
                }
            }
            panning = false
            allowedPan = true
        }
    }
    
    func animateScroll(_ velocity: Double) {
        transformAfterAnimation = offsetTranslation + velocity
        (transformAfterAnimation, _) = normalizeOffsets(transformAfterAnimation, offsetBy: 0)
        
        startAnimationTimer()
        transformBeforeAnimation = Double(sunView.transform.ty)
        
        // TODO: Make scroll duration dynamic
        scrollAnimationDuration = SCROLL_DURATION
        scrolling = true
        
        UIView.animate(withDuration: scrollAnimationDuration, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.sunView.setEasingFunction(Easing.easeOutQuad, forKeyPath: "transform")
            self.sunView.transform = CGAffineTransform(translationX: 0, y: CGFloat(self.transformAfterAnimation))
            }, completion: {finished in
                self.setTransformWhenStopped()
                self.animationStopped = false
        })
    }
    
    @objc func doubleTap(_ recognizer: UITapGestureRecognizer) {
        scrollReset()
    }
    
    func setTransformWhenStopped() {
        self.stopAnimationTimer()
        self.scrolling = false
        self.sunView.removeEasingFunction(forKeyPath: "transform")
        
        let transformDifference = self.transformAfterAnimation - self.transformBeforeAnimation
        let animationDuration = abs(self.animationFireDate.timeIntervalSinceNow) + (1 / 60) // <- this magic number makes view not jump as much when scroll stopping
        
        self.offsetTranslation = Easing.easeOutQuadFunc(animationDuration, startValue: self.transformBeforeAnimation, changeInValue: transformDifference, duration: self.scrollAnimationDuration)
        
        if (!self.animationStopped) {
            self.offsetTranslation = self.transformAfterAnimation
        }
        
        self.setOffsetFromTranslation(self.offsetTranslation)
        moveUpdate(self.offset)
        self.sunView.transform = CGAffineTransform(translationX: 0, y: CGFloat(self.offsetTranslation))
    }
    
    @objc func scrollReset() {
        transformBeforeAnimation = Double(sunView.transform.ty)
        transformAfterAnimation = 0.0
        scrollAnimationDuration = SCROLL_DURATION
        startAnimationTimer()
        scrolling = true
        UIView.animate(withDuration: scrollAnimationDuration, animations: {
            self.sunView.setEasingFunction(Easing.easeOutQuad, forKeyPath: "transform")
            self.sunView.transform = CGAffineTransform(translationX: 0, y: 0)
            }, completion: { finished in
                self.sunView.removeEasingFunction(forKeyPath: "transform")
                self.reset()
                self.update()
        })
    }
    
    func stopScroll() {
        animationStopped = true
        sunView.layer.removeAllAnimations()
        self.setTransformWhenStopped()
    }
    
    @objc func animationUpdate() {
        let transformDifference = self.transformAfterAnimation - self.transformBeforeAnimation
        let ease = Easing.easeOutQuadFunc(animationFireDate.timeIntervalSinceNow * -1, startValue: transformBeforeAnimation, changeInValue: transformDifference, duration:scrollAnimationDuration)
//        print("d: \(animationFireDate.timeIntervalSinceNow * -1) b: \(transformBeforeAnimation) a: \(transformAfterAnimation) ease: \(ease)")
        
        moveUpdate(sun.pointsToMinutes(ease))
    }
    
    @objc func tapGesture(_ recognizer: UITapGestureRecognizer) {
        Bus.sendMessage(.sendMenuIn, data: nil)
    }
    
    @objc func longPressGesture(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            sun.toggleSunAreas()
        }
    }
    
    func touchDown(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
        if scrolling {
            stopScroll()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func centerButtonDidTouch(_ sender: AnyObject) {
        stopAnimationTimer()
        scrollReset()
    }
    
    func collisionIsHappening() {
        if !colliding {
            // Fixes sunline overlap on iphone5 screens and smaller
            nowLeftConstraint.constant = sunView.frame.width < 375 ? 210 : 240
            UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions(), animations: {
                self.nowView.layoutIfNeeded()
                }, completion: nil)
        }
        colliding = true
    }
    
    func collisionNotHappening() {
        if colliding {
            nowLeftConstraint.constant = 100
            UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions(), animations: {
                self.nowView.layoutIfNeeded()
                }, completion: nil)
        }
        colliding = false
    }
}

