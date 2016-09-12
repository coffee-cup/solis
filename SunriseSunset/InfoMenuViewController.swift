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
    
    let ButtonFadeOutDuration: CGFloat = 0.200
    
    var screenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoButtons = [dayButton, civilButton, nauticalButton, astronomicalButton, nightButton]
        twilightLabels = [civilTwilightLabel, nauticalTwilightLabel, astronomicalTwilightLabel]
        
        screenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(sideSwipe))
        screenEdgeRecognizer.edges = .left
        view.addGestureRecognizer(screenEdgeRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("called in view did load")
        
        // Colour Views
        dayView.backgroundColor = risesetColour
        nightView.backgroundColor = astronomicalColour
        
        // Buttons
        dayButton.addSimpleShadow()
        civilButton.addSimpleShadow()
        nauticalButton.addSimpleShadow()
        astronomicalButton.addSimpleShadow()
        nightButton.addSimpleShadow()
        
        for button in infoButtons {
            button.addTarget(self, action: #selector(infoButtonPressed), for: .touchDown)
        }
        
        let highlightColour = UIColor.lightGray
        dayButton.setTitleColor(highlightColour, for: .highlighted)
        civilButton.setTitleColor(highlightColour, for: .highlighted)
        nauticalButton.setTitleColor(highlightColour, for: .highlighted)
        astronomicalButton.setTitleColor(highlightColour, for: .highlighted)
        nightButton.setTitleColor(highlightColour, for: .highlighted)
        
        // Twilight Labels
        civilTwilightLabel.addSimpleShadow()
        nauticalTwilightLabel.addSimpleShadow()
        astronomicalTwilightLabel.addSimpleShadow()
        
        animateButtonsIn()
    }
    
    override func viewDidLayoutSubviews() {
        twilightGradientLayer = CAGradientLayer()
        twilightGradientLayer.frame = twilightView.bounds
        twilightGradientLayer.colors = [risesetColour.cgColor, astronomicalColour.cgColor]
        twilightGradientLayer.locations = [0.0, 1.0]
        twilightView.layer.addSublayer(twilightGradientLayer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    @IBAction func backButtonDidTouch(_ sender: AnyObject) {
        goBack()
    }
    
    func goBack() {
        dismiss(animated: true, completion: nil)
    }
    
    func animateButtonsIn() {
        for (index, button) in infoButtons.enumerated() {
            button.animation = "fadeInRight"
            button.duration = ButtonAnimationDuration
            button.delay = CGFloat(index + 1) * ButtonAnimationDelay
            button.curve = "easeInOut"
            button.animate()
        }
        
        for (index, label) in twilightLabels.enumerated() {
            label.animation = "fadeInRight"
            label.duration = ButtonAnimationDuration
            label.delay = CGFloat(index + 2) * ButtonAnimationDelay + CGFloat(0.250)
            label.curve = "easeInOut"
            label.animate()
        }
    }
    
    func animateButtonsOut(_ completion: (()->())) {
        for (index, button) in infoButtons.enumerated() {
            button.animation = "fadeOut"
            button.duration = ButtonFadeOutDuration
            button.delay = CGFloat(index + 1) * ButtonAnimationDelay
            
            if index == infoButtons.count - 1 {
                button.animateNext(completion)
            } else {
                button.animate()
            }
        }
        
        for (index, label) in twilightLabels.enumerated() {
            label.animation = "fadeOut"
            label.duration = ButtonFadeOutDuration
            label.delay = CGFloat(index + 2) * ButtonAnimationDelay
            label.animate()
        }
    }
    
    func infoButtonPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "InfoSegue", sender: sender)
//        animateButtonsOut() {
//            self.performSegueWithIdentifier("InfoSegue", sender: sender)
//        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if let button = sender as? UIButton {
            if let infoViewController = segue.destination as? InfoViewController {
                var infoData: InfoData!
                if button == dayButton {
                    infoData = InfoData.day
                } else if button == civilButton {
                    infoData = InfoData.civilTwilight
                } else if button == nauticalButton {
                    infoData = InfoData.nauticalTwilight
                } else if button == astronomicalButton {
                    infoData = InfoData.astronomicalTwilight
                } else if button == nightButton {
                    infoData = InfoData.night
                }
                infoViewController.setInfo(infoData)
                
                Analytics.openInfoPage(infoData.title)
            }
        }
    }
    
    func sideSwipe() {
        goBack()
    }
}
