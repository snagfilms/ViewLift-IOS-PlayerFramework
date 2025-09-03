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

// MARK: - TVE Authentication Flow
extension PlayerViewController_tvOS {
    
    /// Starts the TVE login flow and routes to the appropriate UI.
    func loginWithTVE() {
        debugPrint("Login with TVE called")
        
        let type = Configuration.default
        
        switch type {
        case .custom, .customTheme:
            customUIForLogin()
        case .native, .default:
            defaultUIForLogin()
        }
    }
    
    /// Presents a fully-custom activation UI and handles polling.
    private func customUIForLogin() {
        Task {
            do {
                let code = try await VLAuthentication.sharedInstance.generateTVEAuthCode() ?? ""
                let activateURL = "http://spinco.staging.web.viewlift.com/tveactivate?code=\(code)"
                
                debugPrint("Activation Code: \(code)")
                
                // Render QR code for the activation URL.
                let qrCodeImage = TveQRCodeGenerator.generateQRCode(
                    from: activateURL,
                    theme: QRCodeTheme(
                        foregroundColor: .red,
                        backgroundColor: .yellow
                    )
                )
                
                // Begin background polling until the user is authenticated.
                TVEPollingHelper.shared.startPolling(
                    activationCode: code
                ) { [weak self] userIdentity in
                    self?.reloadPlayer(userIdentity: userIdentity)
                    TVEPollingHelper.shared.stopPolling()
                    
                } onFailure: { _ in
                    TVEPollingHelper.shared.stopPolling()
                }
                
            } catch {
                print(error.localizedDescription)
            }
        }
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
