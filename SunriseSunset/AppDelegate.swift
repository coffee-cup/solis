//
//  AppDelegate.swift
//  SunriseSunset
//
//  Created by Jake Runzer on 2016-05-14.
//  Copyright © 2016 Puddllee. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let timeZones = TimeZones()

    func defaultString(_ defaultKey: DefaultKey) -> String {
        return defaultKey.description
    }
    
    internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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
            defaultString(.showSunAreas): true
        ])
        
        BackgroundRefresh.register()

        // Set initial view controller
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let initialViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController")

        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()

        Task {
            await NotificationScheduler.reschedule()
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        BackgroundRefresh.schedule()
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

}

