//
//  PlayerViewController_tvOS+TVEAuthentication.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
#if os(iOS)
import VLAuthentication
#else
import VLAuthentication
#endif
import Foundation
import SwiftUI

// MARK: - TVE Authentication Flow
extension PlayerViewController_tvOS {
    
    /// Starts the TVE login flow and routes to the appropriate UI.
    func loginWithTVE() {
        debugPrint("Login with TVE called")
        
        let type = Configuration.custom
        
        switch type {
        case .custom, .customTheme:
            customUIForLogin()
        case .native, .default:
            defaultUIForLogin()
        }
    }
    
    /// Presents a fully-custom activation UI and handles polling.
    private func customUIForLogin() {
        let hostingController = UIHostingController(
            rootView: TVEPollingQRCodeView()
        )
        
        self.present(hostingController, animated: true)
    }
    
    /// Uses the framework-provided activation screen UI.
    private func defaultUIForLogin() {
        VLAuthentication.sharedInstance.showTVEActivationScreen(
            presentingViewController: self,
            activationURL: "http://spinco.staging.web.viewlift.com/tveactivate",
            qrToggle: true
        ) { [weak self] userIdentity, errorCode in
            // Handle error state (optional).
            if userIdentity == nil, let message = errorCode?.codeString {
                // self?.showAlert(message: message)
                print("Activation failed: \(message)")
                return
            }
            
            // Successful authentication.
            if let user = userIdentity {
                self?.reloadPlayer(userIdentity: user)
            }
        }
    }
    
    /// Refreshes the player instance with the new user identity.
    private func reloadPlayer(userIdentity: VLUserIdentity) {
        DispatchQueue.main.async {
            UserManager.shared.userIdentity = userIdentity
            AppDelegate.shared.authorizationToken = userIdentity.authorizationToken
            
            self.vlPlayer?.destroy()
            self.vlPlayer?.playerVideoAnalyticsDelegate = nil
            self.loadPlayerView()
        }
    }
}
