//
//  MainViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-01.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

protocol MenuProtocol {
    func menuIsMoving(percent: Float)
    func menuStartAnimatingIn()
    func menuStartAnimatingOut()
    func menuIsIn()
    func menuIsOut()
}

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
    
    var delegate: MenuProtocol?
    
    var menuOut = false {
        didSet {
            if menuOut {
//                Bus.sendMessage(.MenuOut, data: nil)
            } else {
//                Bus.sendMessage(.MenuIn, data: nil)
            }
        }
    }
    var holdingWhileOut = false
    
    // Constants
    let MenuAnimaitonDuration: NSTimeInterval = 0.25
    let ClosenessToEdgeIn: CGFloat = 40
    let ClosenessToEdgeOut: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuWidth = menuContainerView.frame.width
        menuHardIn()
        
        addGestureRecognizers()
        Bus.subscribeEvent(.SendMenuIn, observer: self, selector: #selector(sendMenuIn))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
            delegate = sunViewController
        }
    }
    
    // Side Menu
    
//    func animateMenu() {
//        UIView.animateWithDuration(MenuAnimaitonDuration) {
//            self.view.layoutIfNeeded()
//        }
//    }
    
    // Adjusts the x position to be negative in terms of menuWidth
    func adjustNegative(x: CGFloat) -> CGFloat {
        return -menuWidth + x
    }
    
    func menuHardIn() {
        menuLeadingConstraint.constant = adjustNegative(-1)
        menuContainerView.alpha = 0
        menuOut = false
        delegate?.menuIsIn()
    }
    
    func menuSoftIn() {
        menuLeadingConstraint.constant = adjustNegative(-1)
        delegate?.menuStartAnimatingIn()
        UIView.animateWithDuration(MenuAnimaitonDuration, animations: {
            self.view.layoutIfNeeded()
            }, completion: { finished in
                self.menuOut = false
                self.menuContainerView.alpha = 0
                self.delegate?.menuIsIn()
        })
    }
    
    func menuHardOut() {
        menuLeadingConstraint.constant = adjustNegative(menuWidth)
        menuContainerView.alpha = 1
        menuOut = true
        delegate?.menuIsOut()
    }
    
    func menuSoftOut() {
        menuContainerView.alpha = 1
        menuLeadingConstraint.constant = adjustNegative(menuWidth)
        delegate?.menuStartAnimatingOut()
        UIView.animateWithDuration(MenuAnimaitonDuration, animations: {
            self.view.layoutIfNeeded()
            }, completion: { finished in
                self.menuOut = true
                self.delegate?.menuIsOut()
        })
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
        
        delegate?.menuIsMoving(Float(adjustedX / menuWidth))
        
        menuLeadingConstraint.constant = menuTransform
    }
    
    func sideSwipe(recognizer: UIScreenEdgePanGestureRecognizer) {
        let fingerX = recognizer.locationInView(view).x

        if recognizer.state == .Began {
            menuContainerView.alpha = 1
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
            if menuOut && between(Double(fingerX), low: Double(menuWidth - ClosenessToEdgeIn), high: Double(menuWidth + ClosenessToEdgeOut))  {
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
    
    func sendMenuIn() {
        if menuOut {
            menuSoftIn()
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
