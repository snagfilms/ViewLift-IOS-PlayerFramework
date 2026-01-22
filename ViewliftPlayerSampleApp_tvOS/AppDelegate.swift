//
//  AppDelegate.swift
//  ViewLiftPlayerSampleApp_tvOS
//
//  Created by vikassachan@viewlift.com on 16/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit
#if os(iOS)
import VLAuthentication
#else
import VLAuthentication_tvOS
#endif

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var readVideoListOperation:VideoListProtocol?
    
    var authorizationToken: String? = nil
    var adobePlayerTempPass: [String:AdobePassPayload] = [:]

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        readVideoList(readVideoListOperation: ReadFromLocalJson())

        self.setupAuthentication()
        self.setupAnalytics()
        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let assetVC = AssetListViewController()
        assetVC.videoList = readVideoListOperation?.videoList
        let navController = UINavigationController(rootViewController: assetVC)
        navController.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        return true
    }
    
    private func readVideoList(readVideoListOperation: VideoListProtocol) {
        self.readVideoListOperation = readVideoListOperation
        self.readVideoListOperation?.readVideoList()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }


}

