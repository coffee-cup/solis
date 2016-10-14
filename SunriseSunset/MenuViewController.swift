//
//  MenuViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-31.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import UIKit
import PermissionScope

import Crashlytics


class MenuViewController: UIViewController {

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
            button.setTitleColor(buttonDisabled, for: UIControlState())
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
        
        buttonSunrise.setImage(UIImage(named: "rise_off"), for: UIControlState())
        buttonSunrise.setImage(UIImage(named: "rise_on"), for: .selected)
        buttonSunrise.isSelected = defaults.bool(forKey: "Sunrise")
        
        buttonSunset.setImage(UIImage(named: "set_off"), for: UIControlState())
        buttonSunset.setImage(UIImage(named: "set_on"), for: .selected)
        buttonSunset.isSelected = defaults.bool(forKey: "Sunset")
        
        buttonFirstLight.setImage(UIImage(named: "first_off"), for: UIControlState())
        buttonFirstLight.setImage(UIImage(named: "first_on"), for: .selected)
        buttonFirstLight.isSelected = defaults.bool(forKey: "FirstLight")
        
        buttonLastLight.setImage(UIImage(named: "last_off"), for: UIControlState())
        buttonLastLight.setImage(UIImage(named: "last_on"), for: .selected)
        buttonLastLight.isSelected = defaults.bool(forKey: "LastLight")
    }
    
    func timeButtonDidTouch(_ sender: UIButton) {
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
    
    func notificationButtonDidTouch(_ sender: UIButton) {
        getNotificationPermission(sender)
    }
    
    func setLocationLabels() {
        if let locationName = SunLocation.getLocationName() {
            buttonLocation.setTitle(locationName, for: UIControlState())
            currentLocationLabel.isHidden = !SunLocation.isCurrentLocation()
        }
    }
    
    func getNotificationPermission(_ sender: UIButton) {
        let pscope = PermissionScope()
        pscope.style()
        pscope.addPermission(NotificationsPermission(), message: "We only send you notifications for what you allow")
        
        pscope.show({ finished, results in
            
            if results[0].status == PermissionStatus.authorized {
                sender.isSelected = !sender.isSelected
                
                var noti = ""
                switch sender {
                case self.buttonSunrise:
                    noti = "Sunrise"
                case self.buttonSunset:
                    noti = "Sunset"
                case self.buttonFirstLight:
                    noti = "FirstLight"
                case self.buttonLastLight:
                    noti = "LastLight"
                default:
                    noti = ""
                }
                self.defaults.set(sender.isSelected, forKey: noti)
                
                Bus.sendMessage(.notificationChange, data: nil)
                Analytics.toggleNotificationForEvent(sender.isSelected, type: noti)
            }
            }, cancelled: { (results) -> Void in
                print("notification permissions were cancelled")
        })
    }
    
    // Location
    
    func locationUpdate() {
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
