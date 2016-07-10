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
    
    @IBOutlet weak var dayButton: UIButton!
    @IBOutlet weak var civilButton: UIButton!
    @IBOutlet weak var nauticalButton: UIButton!
    @IBOutlet weak var astronomicalButton: UIButton!
    @IBOutlet weak var nightButton: UIButton!
    @IBOutlet weak var civilTwilightLabel: UILabel!
    @IBOutlet weak var nauticalTwilightLabel: UILabel!
    @IBOutlet weak var astronomicalTwilightLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    
    var twilightGradientLayer: CAGradientLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        dismissViewControllerAnimated(true, completion: nil)
    }
}