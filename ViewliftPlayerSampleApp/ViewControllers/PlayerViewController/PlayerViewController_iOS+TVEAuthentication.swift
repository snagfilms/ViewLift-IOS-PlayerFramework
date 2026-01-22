//
//  PlayerViewController_iOS+TVEAuthentication.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
#if os(iOS)
import VLAuthentication
#else
import VLAuthentication_tvOS
#endif
import VLBeaconLib
import Foundation
import VLAnalyticsLib
import SwiftUI

// Handles TVE authentication logic for the player view controller
extension PlayerViewController_iOS {
    
    /// Initiates the TVE login process for the user
    func loginWithTVE() {
        debugPrint("Login with TVE called")
        let type = Configuration.default
        
//        let theme = VLTVEThemeConfig(
//            navigationBarBackgroundColor: .red,
//            navigationBarTitleColor: .green,
//            navigationBarTintColor: .yellow
//        )
//        
//        let initializationConfig: VLTVEInitializationConfig =  VLTVEInitializationConfig(
//            themeConfig: theme
//        )
//        
//        VLAuthentication.sharedInstance.setupTVEConfig(tveInitializationConfig: initializationConfig)
        
        
        switch type {
        case .custom, .customTheme:
            customUIForLogin()
        case .native, .default:
            proceedTVELogin()
        case .disabled:
            break
        }
        
    }
    
    private func customUIForLogin() {
        VLAuthentication.sharedInstance.getTVEProviders { providers, errorCode in
            if let mvpdList = providers, errorCode == nil {
                print(mvpdList)
                
                DispatchQueue.main.async {
                    
                    let swiftUIView = MVPDGridView(mvpdList: mvpdList) { selectedMVPD in
                          self.handleMVPDSelection(selectedMVPD)
                    }
                    
                            
                    let hostingController = UIHostingController(rootView: swiftUIView)
                            
                    hostingController.modalPresentationStyle = .fullScreen
                    self.present(hostingController, animated: true)
                }
            }
        }
        
    }
    
    private func handleMVPDSelection(_ mvpd: AdobeMvpd) {
           // Process the selected MVPD
           print("Processing MVPD: \(mvpd.id) - \(mvpd.displayName)")
        
        VLAuthentication.sharedInstance
            .proceedForloginTVEAuthentication(
                selectedProvider: mvpd,
                presentingViewController: self) { [weak self] userIdentity, errorCode in
                    self?.reloadPlayerAndPerformLogin(errorCode: errorCode, userIdentity: userIdentity)
                }
    }
    
    /// Proceeds with the TVE authentication flow using the VLAuthentication framework
    private func proceedTVELogin() {
        VLAuthentication.sharedInstance.initiateAuthentication(
            authenticationType: .signin, // Specify sign-in authentication
            authenticationClient: .tvProvider(provider: .adobe, tveInitializationConfig: nil),
            presentingViewController: self, // Present authentication UI from this view controller
            beacon: VLBeacon.getInstance() // Pass analytics beacon instance
        ) { [weak self] userIdentity, errorCode in
          self?.reloadPlayerAndPerformLogin(errorCode: errorCode, userIdentity: userIdentity)
        }
    }
    
    private func reloadPlayerAndPerformLogin(errorCode: VLAuthenticationErrorCode?, userIdentity: VLUserIdentity?){
        // Ensure UI updates are performed on the main thread
        DispatchQueue.main.async { [weak self] in
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
