//
//  AppDelegate.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-14.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import UIKit
import GoogleMaps
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let notifications = Notifications()
    let timeZones = TimeZones()

    func defaultString(defaultKey: DefaultKey) -> String {
        return defaultKey.description
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        Defaults.defaults.registerDefaults([
            defaultString(.TimeFormat): "h:mm a",
            defaultString(.FirstLight): false,
            defaultString(.LastLight): false,
            defaultString(.Sunset): false,
            defaultString(.Sunrise): false,
            defaultString(.NotificationPreTime): 60 * 60 * 5, // minutes
            defaultString(.CurrentLocation): true,
            defaultString(.LocationHistoryPlaces): [],
            defaultString(.ShowWalkthrough): true,
            defaultString(.ShowSunAreas): true
        ])
        
        GMSServices.provideAPIKey("AIzaSyATdTWF9AwHXq3UnCrAfr6czN7f_E86658")
        
        application.setMinimumBackgroundFetchInterval(60 * 60 * 12) // 12 hours
        
        // Set initial view controller
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let initViewControllerIdentifier = Defaults.showWalkthrough ? "WalkthroughViewController" : "MainViewController"
        let initialViewController = storyboard.instantiateViewControllerWithIdentifier(initViewControllerIdentifier)
        
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
        
        Fabric.with([Crashlytics.self])
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        let triggered = notifications.scheduleNotifications()
        if triggered {
            completionHandler(.NewData)
        } else {
            completionHandler(.NoData)
        }
    }

}

