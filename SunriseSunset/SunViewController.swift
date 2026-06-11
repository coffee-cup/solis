//
//  ViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-14.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import UIKit
import CoreLocation

class SunViewController: UIViewController, TouchDownProtocol, UIGestureRecognizerDelegate, SunProtocol {

    var sunView: UIView!
    var gradientLayer = CAGradientLayer()

    var nowView: TouchThroughView!
    var nowTimeLabel: UILabel!
    var nowLineView: UIView!
    var nowLabel: UILabel!
    var nowLeftConstraint: NSLayoutConstraint!
    var futureLabel: UILabel!
    var pastLabel: UILabel!

    var noLocationLabel1: UILabel!
    var noLocationLabel2: UILabel!

    var centerImageView: UIImageView!
    var centerButton: UIButton!
    
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

    // How large the sun view is compared to the normal view
    let SunViewScreenMultiplier: CGFloat = 9

    var smoothyOffset: Double = 0
    var smoothyForward = true

    // Closes the slide-out menu when the gradient is tapped while it is out.
    var onTapWhileMenuOut: (() -> Void)?

    // Last-applied model state, diffed in apply()
    private var appliedUpdateToken = 0
    private var appliedChangeToken = 0
    private var appliedResetToken = 0
    private var appliedTimeFormat: String?
    private var appliedThemeID: String?
    
    override func loadView() {
        let root = TouchDownView()
        root.backgroundColor = nauticalColour
        view = root
        touchDownView = root
        touchDownView.delegate = self

        buildViews()
    }

    func buildViews() {
        // Sun gradient view; sized manually in setupIfNeeded and moved with
        // a transform while scrolling, so it stays out of Auto Layout.
        sunView = UIView()
        sunView.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(sunView)

        // "now" marker: passes touches through to the gradient behind it
        nowView = TouchThroughView()
        nowView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nowView)

        nowLabel = UILabel()
        nowLabel.text = "now"
        nowLabel.textAlignment = .right
        nowLabel.translatesAutoresizingMaskIntoConstraints = false
        nowView.addSubview(nowLabel)

        nowLineView = UIView()
        nowLineView.translatesAutoresizingMaskIntoConstraints = false
        nowView.addSubview(nowLineView)

        nowTimeLabel = UILabel()
        nowTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        nowView.addSubview(nowTimeLabel)

        futureLabel = UILabel()
        futureLabel.text = "future"
        futureLabel.font = UIFont(name: fontLight, size: 18)
        futureLabel.textColor = .white
        futureLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(futureLabel)

        pastLabel = UILabel()
        pastLabel.text = "past"
        pastLabel.font = UIFont(name: fontLight, size: 18)
        pastLabel.textColor = .white
        pastLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pastLabel)

        noLocationLabel1 = UILabel()
        noLocationLabel1.text = "I need a location to do anything 🌎"
        noLocationLabel2 = UILabel()
        noLocationLabel2.text = "Enable location services or choose a city from the menu ←"
        for label in [noLocationLabel1!, noLocationLabel2!] {
            label.font = UIFont(name: fontLight, size: 22)
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
        }

        centerButton = UIButton(type: .system)
        centerButton.translatesAutoresizingMaskIntoConstraints = false
        centerButton.addTarget(self, action: #selector(centerButtonDidTouch), for: .touchUpInside)
        centerButton.accessibilityLabel = "center on now"
        view.addSubview(centerButton)

        centerImageView = UIImageView(image: UIImage(named: "center_button"))
        centerImageView.translatesAutoresizingMaskIntoConstraints = false
        centerImageView.isUserInteractionEnabled = false
        view.addSubview(centerImageView)

        let safe = view.safeAreaLayoutGuide
        nowLeftConstraint = nowLineView.leadingAnchor.constraint(equalTo: nowView.leadingAnchor, constant: 100)

        NSLayoutConstraint.activate([
            nowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nowView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            nowView.heightAnchor.constraint(equalToConstant: 50),

            nowLineView.heightAnchor.constraint(equalToConstant: 1),
            nowLeftConstraint,
            nowLineView.trailingAnchor.constraint(equalTo: nowView.trailingAnchor),
            nowLineView.centerYAnchor.constraint(equalTo: nowView.centerYAnchor),

            nowLabel.trailingAnchor.constraint(equalTo: nowView.trailingAnchor, constant: -20),
            nowLabel.bottomAnchor.constraint(equalTo: nowLineView.topAnchor, constant: -2),

            nowTimeLabel.leadingAnchor.constraint(equalTo: nowView.leadingAnchor, constant: 20),
            nowTimeLabel.centerYAnchor.constraint(equalTo: nowLineView.centerYAnchor),

            futureLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            futureLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 10),

            pastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pastLabel.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -10),

            noLocationLabel1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            noLocationLabel1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),
            noLocationLabel1.bottomAnchor.constraint(equalTo: nowView.topAnchor, constant: -60),

            noLocationLabel2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            noLocationLabel2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),
            noLocationLabel2.topAnchor.constraint(equalTo: nowView.bottomAnchor, constant: 40),

            centerButton.widthAnchor.constraint(equalToConstant: 44),
            centerButton.heightAnchor.constraint(equalToConstant: 44),
            centerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            centerButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -30),

            centerImageView.widthAnchor.constraint(equalToConstant: 30),
            centerImageView.heightAnchor.constraint(equalToConstant: 30),
            centerImageView.centerXAnchor.constraint(equalTo: centerButton.centerXAnchor),
            centerImageView.centerYAnchor.constraint(equalTo: centerButton.centerYAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
        centerImageView.alpha = 0

        noLocationLabel1.alpha = 0
        noLocationLabel2.alpha = 0

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

    }

    // Reacts to observable-model changes forwarded by TimelineView.
    func apply(updateToken: Int, changeToken: Int, resetToken: Int, timeFormat: String, themeID: String, isMenuOut: Bool) {
        self.isMenuOut = isMenuOut

        guard sun != nil else {
            appliedUpdateToken = updateToken
            appliedChangeToken = changeToken
            appliedResetToken = resetToken
            appliedTimeFormat = timeFormat
            appliedThemeID = themeID
            return
        }

        if appliedChangeToken != changeToken {
            appliedChangeToken = changeToken
            locationJustChanged = true
        }
        if appliedTimeFormat != timeFormat {
            appliedTimeFormat = timeFormat
            sun.timeFormatUpdate()
        }
        if appliedThemeID != themeID {
            appliedThemeID = themeID
            applyTheme()
        }
        if appliedResetToken != resetToken {
            appliedResetToken = resetToken
            scrollReset()
        }
        if appliedUpdateToken != updateToken {
            appliedUpdateToken = updateToken
            update()
        }
    }

    // Recolours everything from the current palette. Calls sun.update directly
    // (not update()) so the gradient recomputes even while scrolled off rest.
    private func applyTheme() {
        view.backgroundColor = nauticalColour
        gradientLayer.backgroundColor = nauticalColour.cgColor
        guard sun != nil else { return }
        sun.applyTheme()
        if let location = SunLocation.getLocation() {
            sun.update(offset, location: location)
        }
    }

    // The gradient maths capture the view height once; the frame is not
    // trustworthy until the first layout pass, so Sun is built here rather
    // than in viewDidLoad.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupIfNeeded()
    }

    func setupIfNeeded() {
        guard sun == nil, view.bounds.height > 0 else { return }

        let screenMinutes = Float(60 * 6) // 6 hours / screen height
        let screenHeight = Float(view.bounds.height)
        let sunHeight = screenHeight * Float(SunViewScreenMultiplier)

        sunView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: CGFloat(sunHeight))
        sunView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        view.sendSubviewToBack(sunView)

        sun = Sun(screenMinutes: screenMinutes,
                  screenHeight: screenHeight,
                  sunHeight: sunHeight,
                  sunView: sunView,
                  gradientLayer: gradientLayer,
                  nowTimeLabel: nowTimeLabel,
                  nowLabel: nowLabel)
        sun.delegate = self

        reset()
        scrollReset()
        sunView.alpha = 0
        update()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard sun != nil else { return }
        sunView.alpha = 0
        update()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Update every minute
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }

    func startAnimationTimer() {
        animationTimer = Timer.scheduledTimer(timeInterval: 0.06, target: self, selector: #selector(animationUpdate), userInfo: nil, repeats: true)
        animationFireDate = Date()
    }
    
    func stopAnimationTimer() {
        animationTimer.invalidate()
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
        guard sun != nil else { return }
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
            UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut) {
                self.centerImageView.alpha = 1
            }
        } else if !offNow && centerButton.isEnabled {
            centerButton.isEnabled = false
            UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut) {
                self.centerImageView.alpha = 0
            }
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
        
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(Easing.easeOutQuad)
        UIView.animate(withDuration: scrollAnimationDuration, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.sunView.transform = CGAffineTransform(translationX: 0, y: CGFloat(self.transformAfterAnimation))
        }, completion: {finished in
            self.setTransformWhenStopped()
            self.animationStopped = false
        })
        CATransaction.commit()
    }
    
    @objc func doubleTap(_ recognizer: UITapGestureRecognizer) {
        scrollReset()
    }
    
    func setTransformWhenStopped() {
        self.stopAnimationTimer()
        self.scrolling = false

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
        guard sun != nil else { return }
        transformBeforeAnimation = Double(sunView.transform.ty)
        transformAfterAnimation = 0.0
        scrollAnimationDuration = SCROLL_DURATION
        startAnimationTimer()
        scrolling = true
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(Easing.easeOutQuad)
        UIView.animate(withDuration: scrollAnimationDuration, animations: {
            self.sunView.transform = CGAffineTransform(translationX: 0, y: 0)
        }, completion: { finished in
            self.reset()
            self.update()
        })
        CATransaction.commit()
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
        if isMenuOut {
            onTapWhileMenuOut?()
        }
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
    
    @objc func centerButtonDidTouch(_ sender: AnyObject) {
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

