//
//  MainViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-01.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var sunContainerView: UIView!
    @IBOutlet weak var menuContainerView: UIView!
    @IBOutlet weak var menuLeadingConstraint: NSLayoutConstraint!
    
    var menuViewController: MenuViewController!
    var sunViewController: SunViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuHardIn()
        
        let menuRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(sideSwipe))
        menuRecognizer.edges = .Left
        view.addGestureRecognizer(menuRecognizer)
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
    
    // Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "MenuSegue" {
            menuViewController = segue.destinationViewController as! MenuViewController
        } else if segue.identifier == "SunSegue" {
            sunViewController = segue.destinationViewController as! SunViewController
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
