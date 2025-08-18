//
//  PlayerViewController_tvOS+TVEAuthentication.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
#if os(iOS)
import VLAuthenticationFramework
#else
import VLAuthenticationFramework_tvOS
#endif
import Foundation

// Handle TVE authentication flow for the player view controller
extension PlayerViewController_tvOS {
    
    // Initiates TVE login and handles activation screen and user identity updates
    func loginWithTVE() {
        debugPrint("Login with TVE called")
        VLAuthentication.sharedInstance
            .showTVEActivationScreen(
                presentingViewController: self,
                activationURL: "http://spinco.staging.web.viewlift.com/tveactivate",
                qrToggle: true) { [weak self] userIdentity, errorCode in
                    DispatchQueue.main.async {
                        // If authentication fails, handle error (currently commented out)
                        if userIdentity == nil, let codeString = errorCode?.codeString {
                            // self?.showAlert(message: codeString)
                            return
                        }
                        
                        // On successful authentication, update user identity and token
                        UserManager.shared.userIdentity = userIdentity
                        AppDelegate.shared.authorizationToken = userIdentity?.authorizationToken
                        // Destroy current player and clear delegates
                        self?.vlPlayer?.destroy()
                        
                        self?.vlPlayer?.playerVideoAnalyticsDelegate = nil
                        // Reload player view with new authentication context
                        self?.loadPlayerView()
                    }
                }
    }
}
