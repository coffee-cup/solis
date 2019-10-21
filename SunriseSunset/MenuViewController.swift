//
//  MenuViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-31.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import UIKit
import SPPermission

import Crashlytics


class MenuViewController: UIViewController, SPPermissionDialogDelegate {

    let defaults = Defaults.defaults
    @IBOutlet weak var menuView: UIView!
    var screenWidth: CGFloat!
    
    @IBOutlet weak var button24h: UIButton!
    @IBOutlet weak var button12h: UIButton!
    @IBOutlet weak var buttonDelta: UIButton!
    
    @IBOutlet weak var buttonSunrise: UIButton!
    @IBOutlet weak var buttonSunset: UIButton!
    @IBOutlet weak var buttonFirstLight: UIButton!
    @IBOutlet weak var buttonLastLight: UIButton!
    
    @IBOutlet weak var buttonLocation: UIButton!
    @IBOutlet weak var currentLocationLabel: UILabel!
    
    @IBOutlet weak var buttonAbout: UIButton!
    
    var timeButtons: [UIButton]!
    var notificationButtons: [UIButton]!
    var menuButtons: [UIButton] = []
    
    lazy var storyBoard = UIStoryboard(name: "Main", bundle: nil)
    
    var locationChangeViewController: LocationChangeViewController?
    var infoMenuViewController: InfoMenuViewController?
    
    let SoftAnimationDuration: TimeInterval = 1
    
    var notificationText: String?
    var notificationSelected: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        screenWidth = view.frame.width
        
        // Shadow
//        let shadowPath = UIBezierPath(rect: menuView.bounds)
//        menuView.layer.masksToBounds = false
//        menuView.layer.shadowColor = UIColor.blackColor().CGColor
//        menuView.layer.shadowOffset = CGSizeMake(2, 2)
//        menuView.layer.shadowOpacity = 0.2;
//        menuView.layer.shadowPath = shadowPath.CGPath
        
        menuView.backgroundColor = menuBackgroundColour
        
        timeButtons = [button12h, button24h, buttonDelta]
        notificationButtons = [buttonSunrise, buttonSunset, buttonFirstLight, buttonLastLight]
        menuButtons = timeButtons + notificationButtons
        
        Bus.subscribeEvent(.locationUpdate, observer: self, selector: #selector(locationUpdate))
        
        setupButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setLocationLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        Bus.removeSubscriptions(self)
    }
    
    func setupButtons() {
        
        // All buttons
        for button in menuButtons {
            button.setTitleColor(buttonDisabled, for: UIControl.State())
            button.setTitleColor(buttonEnabled, for: .selected)
//            button.setTitleColor(buttonHighlighted, forState: .Highlighted)
        }
        
        // Time buttons
        for button in timeButtons {
            button.addTarget(self, action: #selector(timeButtonDidTouch), for: .touchUpInside)
        }
        
        let timeFormat = defaults.string(forKey: MessageType.timeFormat.description)
        if timeFormat == TimeFormat.hour24.description {
            button24h.isSelected = true
        } else if timeFormat == TimeFormat.hour12.description {
            button12h.isSelected = true
        } else if timeFormat == TimeFormat.delta.description {
            buttonDelta.isSelected = true
        }
        
        // Notification buttons
        for button in notificationButtons {
            button.addTarget(self, action: #selector(notificationButtonDidTouch), for: .touchUpInside)
        }
        
        buttonSunrise.setImage(UIImage(named: "rise_off"), for: UIControl.State())
        buttonSunrise.setImage(UIImage(named: "rise_on"), for: .selected)
        buttonSunrise.isSelected = defaults.bool(forKey: "Sunrise")
        
        buttonSunset.setImage(UIImage(named: "set_off"), for: UIControl.State())
        buttonSunset.setImage(UIImage(named: "set_on"), for: .selected)
        buttonSunset.isSelected = defaults.bool(forKey: "Sunset")
        
        buttonFirstLight.setImage(UIImage(named: "first_off"), for: UIControl.State())
        buttonFirstLight.setImage(UIImage(named: "first_on"), for: .selected)
        buttonFirstLight.isSelected = defaults.bool(forKey: "FirstLight")
        
        buttonLastLight.setImage(UIImage(named: "last_off"), for: UIControl.State())
        buttonLastLight.setImage(UIImage(named: "last_on"), for: .selected)
        buttonLastLight.isSelected = defaults.bool(forKey: "LastLight")
    }
    
    @objc func timeButtonDidTouch(_ sender: UIButton) {
        if !sender.isSelected {
            for button in timeButtons {
                button.isSelected = false
            }
            sender.isSelected = true
            
            var timeFormat = ""
            if sender == button24h {
                timeFormat = TimeFormat.hour24.description
            } else if sender == button12h {
                timeFormat = TimeFormat.hour12.description
            } else if sender == buttonDelta {
                timeFormat = TimeFormat.delta.description
            }
            defaults.set(timeFormat, forKey: MessageType.timeFormat.description)
            Bus.sendMessage(.timeFormat, data: nil)
        }
    }
    
    @objc func notificationButtonDidTouch(_ sender: UIButton) {
        getNotificationPermission(sender)
    }
    
    func setLocationLabels() {
        if let locationName = SunLocation.getLocationName() {
            buttonLocation.setTitle(locationName, for: UIControl.State())
            currentLocationLabel.isHidden = !SunLocation.isCurrentLocation()
        }
    }
    
    func getNotificationPermission(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        notificationSelected = sender.isSelected
        
        switch sender {
        case self.buttonSunrise:
            notificationText = "Sunrise"
        case self.buttonSunset:
            notificationText = "Sunset"
        case self.buttonFirstLight:
            notificationText = "FirstLight"
        case self.buttonLastLight:
            notificationText = "LastLight"
        default:
            notificationText = ""
        }
        
        if SPPermission.isAllowed(.notification) {
            notificationPermissionCallback()
        } else {
            SPPermission.Dialog.request(with: [.notification], on: self, delegate: self, dataSource: PermissionController())
        }
    }
    
    func notificationPermissionCallback() {
        if let noti = notificationText {
            if let selected = notificationSelected {
                self.defaults.set(notificationSelected, forKey: noti)
                Bus.sendMessage(.notificationChange, data: nil)
                Analytics.toggleNotificationForEvent(selected, type: noti)
            }
        }
        
        notificationText = nil
        notificationSelected = nil
    }
    
    @objc func didAllow(permission: SPPermissionType) {
        notificationPermissionCallback()
    }
    
    // Location
    
    @objc func locationUpdate() {
        setLocationLabels()
    }
    
    func viewControllerWithIdentifier(_ identifier: String) -> UIViewController {
        return storyBoard.instantiateViewController(withIdentifier: identifier)
    }

    @IBAction func locationButtonDidTouch(_ sender: AnyObject) {
        performSegue(withIdentifier: "LocationChangeSegue", sender: self)
        Analytics.openLocationChange()
    }
    
    @IBAction func aboutButtonDidTouch(_ sender: AnyObject) {
        performSegue(withIdentifier: "InfoMenuSegue", sender: self)
        Analytics.openInfoMenu()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
