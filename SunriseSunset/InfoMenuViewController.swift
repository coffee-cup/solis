//
//  InfoMenuViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-07-05.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class InfoMenuViewController: UIViewController {
    
    @IBOutlet weak var dayView: UIView!
    @IBOutlet weak var twilightView: UIView!
    @IBOutlet weak var nightView: UIView!
    
    @IBOutlet weak var dayButton: SpringButton!
    @IBOutlet weak var civilButton: SpringButton!
    @IBOutlet weak var nauticalButton: SpringButton!
    @IBOutlet weak var astronomicalButton: SpringButton!
    @IBOutlet weak var nightButton: SpringButton!
    @IBOutlet weak var civilTwilightLabel: SpringLabel!
    @IBOutlet weak var nauticalTwilightLabel: SpringLabel!
    @IBOutlet weak var astronomicalTwilightLabel: SpringLabel!
    
    @IBOutlet weak var backButton: UIButton!
    
    var infoButtons: [SpringButton] = []
    var twilightLabels: [SpringLabel] = []
    
    var twilightGradientLayer: CAGradientLayer!
    
    let ButtonAnimationDuration: CGFloat = 1
    let ButtonAnimationDelay: CGFloat = 0.200
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoButtons = [dayButton, civilButton, nauticalButton, astronomicalButton, nightButton]
        twilightLabels = [civilTwilightLabel, nauticalTwilightLabel, astronomicalTwilightLabel]
        
        // Colour Views
        dayView.backgroundColor = risesetColour
        nightView.backgroundColor = astronomicalColour
        
        twilightGradientLayer = CAGradientLayer()
        twilightGradientLayer.frame = twilightView.bounds
        twilightGradientLayer.colors = [risesetColour.CGColor, astronomicalColour.CGColor]
        twilightGradientLayer.locations = [0.0, 1.0]
        twilightView.layer.addSublayer(twilightGradientLayer)
        
        // Buttons
        dayButton.addSimpleShadow()
        civilButton.addSimpleShadow()
        nauticalButton.addSimpleShadow()
        astronomicalButton.addSimpleShadow()
        nightButton.addSimpleShadow()
        
        for button in infoButtons {
            button.addTarget(self, action: #selector(infoButtonPressed), forControlEvents: .TouchDown)
        }
        
        let highlightColour = UIColor.lightGrayColor()
        dayButton.setTitleColor(highlightColour, forState: .Highlighted)
        civilButton.setTitleColor(highlightColour, forState: .Highlighted)
        nauticalButton.setTitleColor(highlightColour, forState: .Highlighted)
        astronomicalButton.setTitleColor(highlightColour, forState: .Highlighted)
        nightButton.setTitleColor(highlightColour, forState: .Highlighted)
        
        // Twilight Labels
        civilTwilightLabel.addSimpleShadow()
        nauticalTwilightLabel.addSimpleShadow()
        astronomicalTwilightLabel.addSimpleShadow()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        animateButtonsIn()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    @IBAction func backButtonDidTouch(sender: AnyObject) {
        goBack()
    }
    
    func goBack() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func animateButtonsIn() {
        for (index, button) in infoButtons.enumerate() {
            button.animation = "fadeInRight"
            button.duration = ButtonAnimationDuration
            button.delay = CGFloat(index + 1) * ButtonAnimationDelay
            button.curve = "easeInOut"
            button.animate()
        }
        
        for (index, label) in twilightLabels.enumerate() {
            label.animation = "fadeInRight"
            label.duration = ButtonAnimationDuration
            label.delay = CGFloat(index + 2) * ButtonAnimationDelay + CGFloat(0.250)
            label.curve = "easeInOut"
            label.animate()
        }
    }
    
    func animateButtonsOut(completion: (()->())) {
        for (index, button) in infoButtons.enumerate() {
            button.animation = "fadeOut"
            button.duration = 0.5
            button.delay = CGFloat(index + 1) * ButtonAnimationDelay
            
            if index == infoButtons.count - 1 {
                button.animateNext(completion)
            } else {
                button.animate()
            }
        }
        
        for (index, label) in twilightLabels.enumerate() {
            label.animation = "fadeOut"
            label.duration = 0.5
            label.delay = CGFloat(index + 2) * ButtonAnimationDelay
            label.animate()
        }
    }
    
    func infoButtonPressed(sender: AnyObject) {
        animateButtonsOut() {
            self.performSegueWithIdentifier("InfoSegue", sender: sender)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let button = sender as? UIButton {
            if let infoViewController = segue.destinationViewController as? InfoViewController {
                if let title = button.currentTitle {
                    infoViewController.setInfo(title)
                }
            }
        }
    }
}