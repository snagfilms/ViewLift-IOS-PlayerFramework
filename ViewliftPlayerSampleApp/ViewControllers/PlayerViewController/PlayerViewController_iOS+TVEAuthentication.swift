//
//  PlayerViewController_iOS+TVEAuthentication.swift
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
import VLBeaconLib
import Foundation
import VLAnalyticsLib

// Handles TVE authentication logic for the player view controller
extension PlayerViewController_iOS {
    
    /// Initiates the TVE login process for the user
    func loginWithTVE() {
        debugPrint("Login with TVE called")
        proceedTVELogin()
    }
    
    /// Proceeds with the TVE authentication flow using the VLAuthentication framework
    private func proceedTVELogin() {
        VLAuthentication.sharedInstance.initiateAuthentication(
            authenticationType: .signin, // Specify sign-in authentication
            authenticationClient: .tvProvider(provider: .adobe, tveInitializationConfig: nil),
            presentingViewController: self, // Present authentication UI from this view controller
            beacon: VLBeacon.getInstance() // Pass analytics beacon instance
        ) { [weak self] userIdentity, errorCode in
            // Ensure UI updates are performed on the main thread
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let errorCode = errorCode {
                    switch errorCode {
                    case .adobeErrorResponse(_, _, let errorMessage, let shouldPerformLogout):
                        
                        if shouldPerformLogout == true {
                            self.showAlert(
                                title: "Error",
                                message: errorMessage
                            ) {
                                self.performLogout(isForceLogout: true)
                            }
                        }
                        return
                    default:
                        break
                    }
                }
                // If authentication failed, show error alert
                if userIdentity == nil, let codeString = errorCode?.codeString {
                    self.showAlert(message: codeString)
                    return
                }
                
                // On successful authentication, update user identity and authorization token
                UserManager.shared.userIdentity = userIdentity
                AppDelegate.shared.authorizationToken = userIdentity?.authorizationToken
                // Destroy the current player and its delegates to reset state
                self.vlPlayer?.destroy()
                self.vlPlayer?.playerVideoAnalyticsDelegate = nil

                // Reload the player view with the new authentication context
                Task {
                    await self.loadPlayerView()
                }
                self.logoutButton.isHidden = false
                
            }
        }
    }
    
//    func analyticsTVELoginSuccess(userIdentity: VLUserIdentity?) {
//        // trigger Analytics
//        let userInfo = VLUserInfo(contentHub: "Adobe Pass",
//                            passNetwork: AnalyticsHelper.shared.requestorId,
//                            passMvpd: userIdentity?.mvpdProvider,
//                            passGuid: userIdentity?.tveUserId ?? "")
//                   
//        AnalyticsHelper.shared.triggerAnalytics(event: .tveLoginSuccess, userInfo: userInfo)
//    }
//    
//    func analyticsTVELoginFail(userIdentity: VLUserIdentity?) {
//        // trigger Analytics
//        let userInfo = VLUserInfo(contentHub: "Adobe Pass",
//                            passNetwork: AnalyticsHelper.shared.requestorId,
//                            passMvpd: userIdentity?.mvpdProvider,
//                            passGuid: userIdentity?.tveUserId ?? "")
//                   
//        AnalyticsHelper.shared
//            .triggerAnalytics(event: .tveLoginFailure, userInfo: userInfo)
//    }
    
}
