//
//  AppDelegate.swift
//  ViewliftPlayerSampleApp
//
//  Created by Abhinav Saldi on 01/05/18.
//  Copyright © 2018 Viewlift. All rights reserved.
//

import UIKit
import VLPlayerLib
#if os(iOS)
import VLAuthentication
#else
import VLAuthentication_tvOS
#endif
import GoogleCast
import VLAnalyticsLib


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var isFullScreen: Bool = false
    var window: UIWindow?
    var authorizationToken: String? = nil
    var readVideoListOperation:VideoListProtocol?
    var isCastingViewVisible: Bool = false
    var castContextSharedInstance: GCKCastContext?
    var adobePlayerTempPass: [String:AdobePassPayload] = [:]

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        self.readVideoList(readVideoListOperation: ReadFromLocalJson())
        // Get current user identity before async context
        
        self.setupAuthentication()
        
//        var adobeConfig = AdobeAnalyticsConfig()
//        adobeConfig.reportSuites = "fanmsnbcottdev"
//        adobeConfig.playerName = "VL Test"
//        AdobeAnalyticsConfigurationHelper.setupAdobeConfiguration(with: adobeConfig)
        
        self.setupAnalytics()

        return true
    }

    private func readVideoList(readVideoListOperation: VideoListProtocol) {
        self.readVideoListOperation = readVideoListOperation
        self.readVideoListOperation?.readVideoList()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Check if player orientation is locked - this takes priority over everything
//        if VLPlayerOrientationManager.isOrientationLocked {
//            debugPrint("🔒 AppDelegate: Orientation locked, returning landscape only")
//            return VLPlayerOrientationManager.lockedOrientation
//        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        } else {
            if let topVC = topViewController(window?.rootViewController), let _ = topVC as? PlayerViewController_iOS {
                return [.portrait, .landscapeLeft, .landscapeRight]
            }
            return [.portrait]
        }
    }

    private func topViewController(_ rootViewController: UIViewController?) -> UIViewController? {
        if let nav = rootViewController as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = rootViewController as? UITabBarController {
            return topViewController(tab.selectedViewController)
        }
        if let presented = rootViewController?.presentedViewController {
            return topViewController(presented)
        }
        return rootViewController
    }
}

