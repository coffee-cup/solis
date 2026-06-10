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

    var infoButtons: [UIButton] = []
    var twilightLabels: [UILabel] = []

    var twilightGradientLayer: CAGradientLayer!

    let ButtonAnimationDuration: TimeInterval = 1
    let ButtonAnimationDelay: TimeInterval = 0.200
    
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
            fadeInFromLeft(button, delay: TimeInterval(index + 1) * ButtonAnimationDelay)
        }

        for (index, label) in twilightLabels.enumerated() {
            fadeInFromLeft(label, delay: TimeInterval(index + 2) * ButtonAnimationDelay + 0.250)
        }
    }

    func fadeInFromLeft(_ view: UIView, delay: TimeInterval) {
        view.alpha = 0
        view.transform = CGAffineTransform(translationX: -300, y: 0)
        UIView.animate(withDuration: ButtonAnimationDuration, delay: delay, options: .curveEaseInOut) {
            view.alpha = 1
            view.transform = .identity
        }
    }
    
    @objc func infoButtonPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "InfoSegue", sender: sender)
//        animateButtonsOut() {
//            self.performSegueWithIdentifier("InfoSegue", sender: sender)
//        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
            }
        }
    }
    
    @objc func sideSwipe() {
        goBack()
    }
}
