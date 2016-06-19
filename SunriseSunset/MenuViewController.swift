//
//  MenuViewController.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-31.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import UIKit
import PermissionScope

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
    
    var timeButtons: [UIButton]!
    var notificationButtons: [UIButton]!
    var menuButtons: [UIButton] = []
    
    let SoftAnimationDuration: NSTimeInterval = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        screenWidth = view.frame.width
        
        // Shadow
        let shadowPath = UIBezierPath(rect: menuView.bounds)
        menuView.layer.masksToBounds = false
        menuView.layer.shadowColor = UIColor.blackColor().CGColor
        menuView.layer.shadowOffset = CGSizeMake(2, 2)
        menuView.layer.shadowOpacity = 0.2;
        menuView.layer.shadowPath = shadowPath.CGPath
        
        menuView.backgroundColor = menuBackgroundColour
        
        timeButtons = [button12h, button24h, buttonDelta]
        notificationButtons = [buttonSunrise, buttonSunset, buttonFirstLight, buttonLastLight]
        menuButtons = timeButtons + notificationButtons
        
        Bus.subscribeEvent(.LocationUpdate, observer: self, selector: #selector(locationUpdate))
        
        setupButtons()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
            button.setTitleColor(buttonDisabled, forState: .Normal)
            button.setTitleColor(buttonEnabled, forState: .Selected)
            button.setTitleColor(buttonHighlighted, forState: .Highlighted)
        }
        
        // Time buttons
        for button in timeButtons {
            button.addTarget(self, action: #selector(timeButtonDidTouch), forControlEvents: .TouchUpInside)
        }
        
        let timeFormat = defaults.stringForKey(MessageType.TimeFormat.description)
        if timeFormat == TimeFormat.hour24.description {
            button24h.selected = true
        } else if timeFormat == TimeFormat.hour12.description {
            button12h.selected = true
        } else if timeFormat == TimeFormat.delta.description {
            buttonDelta.selected = true
        }
        
        // Notification buttons
        for button in notificationButtons {
            button.addTarget(self, action: #selector(notificationButtonDidTouch), forControlEvents: .TouchUpInside)
        }
        
        buttonSunrise.setImage(UIImage(named: "rise_off"), forState: .Normal)
        buttonSunrise.setImage(UIImage(named: "rise_on"), forState: .Selected)
        buttonSunrise.selected = defaults.boolForKey("Sunrise")
        
        buttonSunset.setImage(UIImage(named: "set_off"), forState: .Normal)
        buttonSunset.setImage(UIImage(named: "set_on"), forState: .Selected)
        buttonSunset.selected = defaults.boolForKey("Sunset")
        
        buttonFirstLight.setImage(UIImage(named: "first_off"), forState: .Normal)
        buttonFirstLight.setImage(UIImage(named: "first_on"), forState: .Selected)
        buttonFirstLight.selected = defaults.boolForKey("FirstLight")
        
        buttonLastLight.setImage(UIImage(named: "last_off"), forState: .Normal)
        buttonLastLight.setImage(UIImage(named: "last_on"), forState: .Selected)
        buttonLastLight.selected = defaults.boolForKey("LastLight")
    }
    
    func timeButtonDidTouch(sender: UIButton) {
        if !sender.selected {
            for button in timeButtons {
                button.selected = false
            }
            sender.selected = true
            
            var timeFormat = ""
            if sender == button24h {
                timeFormat = TimeFormat.hour24.description
            } else if sender == button12h {
                timeFormat = TimeFormat.hour12.description
            } else if sender == buttonDelta {
                timeFormat = TimeFormat.delta.description
            }
            defaults.setObject(timeFormat, forKey: MessageType.TimeFormat.description)
            Bus.sendMessage(.TimeFormat, data: nil)
        }
    }
    
    func notificationButtonDidTouch(sender: UIButton) {
        getNotificationPermission(sender)
    }
    
    func getNotificationPermission(sender: UIButton) {
        let pscope = PermissionScope()
        pscope.addPermission(NotificationsPermission(), message: "We only send you notifications for what you allow.")
        
        pscope.show({ finished, results in
            sender.selected = !sender.selected
            
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
            self.defaults.setBool(sender.selected, forKey: noti)
            
            Bus.sendMessage(.NotificationChange, data: nil)
            }, cancelled: { (results) -> Void in
                print("notification permissions were cancelled")
        })
    }
    
    // Location
    
    func locationUpdate() {
        if let location = Location.getLocation() {
            print(location)
            let locationString = "\(Int(location.latitude)), \(Int(location.longitude))"
            buttonLocation.setTitle(locationString, forState: .Normal)
        }
    }

    @IBAction func locationButtonDidTouch(sender: AnyObject) {
//        performSegueWithIdentifier("LocationChangeSegue", sender: self)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let locationChangeViewController = storyboard.instantiateViewControllerWithIdentifier("LocationChange") as? LocationChangeViewController {
            locationChangeViewController.modalPresentationStyle = .OverCurrentContext
            presentViewController(locationChangeViewController, animated: true) {
                Bus.sendMessage(.ShowStatusBar, data: nil)
            }
        }
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
