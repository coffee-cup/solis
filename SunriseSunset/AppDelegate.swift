//
//  AppDelegate.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-14.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import UIKit
import GooglePlaces
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var notifications: Notifications!
    let timeZones = TimeZones()

    let GoogleAPIKey = "AIzaSyATdTWF9AwHXq3UnCrAfr6czN7f_E86658"
    
    func defaultString(_ defaultKey: DefaultKey) -> String {
        return defaultKey.description
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        Defaults.defaults.register(defaults: [
            defaultString(.timeFormat): "h:mm a",
            defaultString(.firstLight): false,
            defaultString(.lastLight): false,
            defaultString(.sunset): false,
            defaultString(.sunrise): false,
            defaultString(.notificationPreTime): 60 * 60 * 5, // minutes
            defaultString(.currentLocation): true,
            defaultString(.locationHistoryPlaces): [],
            defaultString(.showWalkthrough): true,
            defaultString(.showSunAreas): true
        ])
        
        GMSPlacesClient.provideAPIKey(GoogleAPIKey)
        
        application.setMinimumBackgroundFetchInterval(60 * 60 * 3) // 3 hours
        
        // Set initial view controller
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let initViewControllerIdentifier = Defaults.showWalkthrough ? "WalkthroughViewController" : "MainViewController"
        let initialViewController = storyboard.instantiateViewController(withIdentifier: initViewControllerIdentifier)
        
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
        
        #if RELEASE
            Fabric.with([Crashlytics.self])
        #else
            print("DEBUG MODE")
        #endif
            
        // This MUST come after Fabric has been initialized
        notifications = Notifications()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if notifications == nil {
            notifications = Notifications()
        }
        
        _ = notifications.scheduleNotifications()
        notifications.checkIfNotificationsTriggered()
        
        completionHandler(.newData)
    }

}

