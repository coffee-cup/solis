//
//  InfoViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-07-13.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class InfoViewController: UIViewController {
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var navigationBarItem: UINavigationItem!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var learnMoreButton: UIButton!
    
    var infoTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: fontLight, size: 16)!]
        learnMoreButton.addUnderline()
        learnMoreButton.setTitleColor(astronomicalColour, forState: .Normal)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationBarItem.title = infoTitle
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    func goBack() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setInfo(title: String) {
        self.infoTitle = title
    }
    
    @IBAction func backButtonDidTouch(sender: AnyObject) {
        goBack()
    }
}