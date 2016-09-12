//
//  MainViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-01.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol MenuProtocol {
    func menuIsMoving(_ percent: Float)
    func menuStartAnimatingIn()
    func menuStartAnimatingOut()
    func menuIsIn()
    func menuIsOut()
}

class MainViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var sunContainerView: UIView!
    @IBOutlet weak var menuContainerView: UIView!
    @IBOutlet weak var menuLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var menuImageView: SpringImageView!
    
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
    let MenuAnimaitonDuration: TimeInterval = 0.25
    let ClosenessToEdgeIn: CGFloat = 40
    let ClosenessToEdgeOut: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuWidth = menuContainerView.frame.width
        menuHardIn()
        
        addGestureRecognizers()
        Bus.subscribeEvent(.sendMenuIn, observer: self, selector: #selector(sendMenuIn))
        
        menuImageView.duration = CGFloat(1)
        menuImageView.curve = "easeInOut"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func addGestureRecognizers() {
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(menuPan))
        view.addGestureRecognizer(panRecognizer)
        
        menuRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(sideSwipe))
        menuRecognizer.edges = .left
        menuRecognizer.delegate = self
        view.addGestureRecognizer(menuRecognizer)
    }
    
    // Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "MenuSegue" {
            menuViewController = segue.destination as! MenuViewController
        } else if segue.identifier == "SunSegue" {
            sunViewController = segue.destination as! SunViewController
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
    func adjustNegative(_ x: CGFloat) -> CGFloat {
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
        UIView.animate(withDuration: MenuAnimaitonDuration, animations: {
            self.view.layoutIfNeeded()
            }, completion: { finished in
                self.menuOut = false
                self.menuContainerView.alpha = 0
                self.delegate?.menuIsIn()
        })
        sendMenuButtonOut()
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
        UIView.animate(withDuration: MenuAnimaitonDuration, animations: {
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
    
    func menuToFinger(_ x: CGFloat) {
        let adjustedX = x > menuWidth ? menuWidth : x
        let menuTransform = adjustNegative(adjustedX!)
        
        delegate?.menuIsMoving(Float(adjustedX! / menuWidth))
        
        menuLeadingConstraint.constant = menuTransform
    }
    
    func sideSwipe(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        let fingerX = recognizer.location(in: view).x

        if recognizer.state == .began {
            menuContainerView.alpha = 1
            if !menuOut {
                sendMenuButtonIn()
            }
        } else if recognizer.state == .changed {
            if !menuOut {
                menuToFinger(fingerX)
            }
        } else if recognizer.state == .ended {
            menuInOut()
        }
    }
    
    func between(_ val: Double, low: Double, high: Double) -> Bool {
        return val >= low && val <= high
    }
    
    func menuPan(_ recognizer: UIPanGestureRecognizer) {
        let fingerX = recognizer.location(in: view).x
    
        if recognizer.state == .began {
            if menuOut && between(Double(fingerX), low: Double(menuWidth - ClosenessToEdgeIn), high: Double(menuWidth + menuWidth))  {
                holdingWhileOut = true
                anchorX = menuWidth - fingerX
            }
        } else if recognizer.state == .changed {
            if holdingWhileOut {
                menuToFinger(fingerX + anchorX)
            }
        } else if recognizer.state == .ended {
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
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func sendMenuButtonOut() {
        menuImageView.animation = "fadeIn"
        menuImageView.animate()
    }
    
    func sendMenuButtonIn() {
        menuImageView.animation = "fadeOut"
        menuImageView.animate()
    }
    
    @IBAction func menuButtonDidTouch(_ sender: AnyObject) {
        menuSoftOut()
        
        sendMenuButtonIn()
    }
}
