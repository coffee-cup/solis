//
//  MainViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-01.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class MainViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var sunContainerView: UIView!
    @IBOutlet weak var menuContainerView: UIView!
    @IBOutlet weak var menuLeadingConstraint: NSLayoutConstraint!
    
    var menuViewController: MenuViewController!
    var sunViewController: SunViewController!
    
    // recognizers
    var menuRecognizer: UIScreenEdgePanGestureRecognizer!
    var panRecognizer: UIPanGestureRecognizer!
    
    var menuWidth: CGFloat!
    var anchorX: CGFloat = 0
    
    var menuOut = false
    var holdingWhileOut = false
    
    // Constants
    let MenuAnimaitonDuration: NSTimeInterval = 0.25
    let ClosenessToEdge: CGFloat = 40
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addGestureRecognizers()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        menuWidth = menuContainerView.frame.width
        menuHardIn()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func addGestureRecognizers() {
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(menuPan))
        view.addGestureRecognizer(panRecognizer)
        
        menuRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(sideSwipe))
        menuRecognizer.edges = .Left
        menuRecognizer.delegate = self
        view.addGestureRecognizer(menuRecognizer)
    }
    
    // Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "MenuSegue" {
            menuViewController = segue.destinationViewController as! MenuViewController
        } else if segue.identifier == "SunSegue" {
            sunViewController = segue.destinationViewController as! SunViewController
        }
    }
    
    // Side Menu
    
    func animateMenu() {
        UIView.animateWithDuration(MenuAnimaitonDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    // Adjusts the x position to be negative in terms of menuWidth
    func adjustNegative(x: CGFloat) -> CGFloat {
        return -menuWidth + x
    }
    
    func menuHardIn() {
        menuLeadingConstraint.constant = adjustNegative(-1)
        menuOut = false
    }
    
    func menuSoftIn() {
        menuHardIn()
        animateMenu()
    }
    
    func menuHardOut() {
        menuLeadingConstraint.constant = adjustNegative(menuWidth)
        menuOut = true
    }
    
    func menuSoftOut() {
        menuHardOut()
        animateMenu()
    }
    
    // Moves the menu in or out depending on its position now
    func menuInOut() {
        let position = menuLeadingConstraint.constant
        
        if menuWidth + position > menuWidth / 2 {
            menuSoftOut()
        } else {
            menuSoftIn()
        }
    }
    
    func menuToFinger(x: CGFloat) {
        let adjustedX = x > menuWidth ? menuWidth : x
        let menuTransform = adjustNegative(adjustedX)
        
        menuLeadingConstraint.constant = menuTransform
    }
    
    func sideSwipe(recognizer: UIScreenEdgePanGestureRecognizer) {
        let fingerX = recognizer.locationInView(view).x

        if recognizer.state == .Began {
        } else if recognizer.state == .Changed {
            if !menuOut {
                menuToFinger(fingerX)
            }
        } else if recognizer.state == .Ended {
            menuInOut()
        }
    }
    
    func between(val: Double, low: Double, high: Double) -> Bool {
        return val >= low && val <= high
    }
    
    func menuPan(recognizer: UIPanGestureRecognizer) {
        let fingerX = recognizer.locationInView(view).x
    
        if recognizer.state == .Began {
            if menuOut && between(Double(fingerX), low: Double(menuWidth - ClosenessToEdge), high: Double(menuWidth + ClosenessToEdge))  {
                holdingWhileOut = true
                anchorX = menuWidth - fingerX
            }
        } else if recognizer.state == .Changed {
            if holdingWhileOut {
                menuToFinger(fingerX + anchorX)
            }
        } else if recognizer.state == .Ended {
            if holdingWhileOut {
                menuInOut()
                holdingWhileOut = false
            }
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
