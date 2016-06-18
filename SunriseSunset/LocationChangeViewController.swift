//
//  LocationChangeViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-06-17.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import Foundation
import UIKit

class LocationChangeViewController: UIViewController {
    
    @IBOutlet weak var buttonCancel: UIBarButtonItem!
    @IBOutlet weak var buttonSet: UIBarButtonItem!
    
    var hideStatusBar = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Bus.subscribeEvent(.ShowStatusBar, observer: self, selector: #selector(showStatusBar))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        Bus.removeSubscriptions(self)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return hideStatusBar
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Fade
    }
    
    func showStatusBar() {
        hideStatusBar = false
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func goBack() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelButtonDidTouch(sender: AnyObject) {
        goBack()
    }
    
    @IBAction func setButtonDidTouch(sender: AnyObject) {
        goBack()
    }
}
