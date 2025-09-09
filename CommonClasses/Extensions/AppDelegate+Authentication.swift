//
//  AppDelegate+Authentication.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 04/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import UIKit
#if os(iOS)
import VLAuthentication
#else
import VLAuthentication_tvOS
#endif
import VLAnalyticsLib

// Extension to AppDelegate for handling authentication logic
extension AppDelegate {
    // Shared instance of AppDelegate for easy access
    static var shared: AppDelegate {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Could not cast UIApplication delegate as AppDelegate")
        }
        return delegate
    }
    
    // Sets up authentication configuration and manages tokens
    func setupAuthentication() {
        // Retrieve current user identity and authorization token
        let userIdentity = UserManager.shared.userIdentity
        self.authorizationToken = userIdentity?.authorizationToken
        
        // Ensure video list and authentication keys are available
        guard let videoList = AppDelegate.shared.readVideoListOperation?.videoList else{
            return
        }
        let xApiKey: String = videoList.xApiKey
        let siteId: String = videoList.authKeys.siteId
        let apiBaseEndpoint: String = videoList.authKeys.apiBaseEndpoint
        
        // Create API configuration object
        let apiConfig = APIConfig(
            xApiKey: xApiKey,
            identifier: .siteId(siteId), //here you can also pass web domain.
            authorizationToken: authorizationToken,
            apiBaseUrl: apiBaseEndpoint
        )
        
        // Perform authentication
        Task { [weak self] in
            do {
                guard let self = self else { return }
                
                // Initialize authentication framework with API con fig
                try await VLAuthentication.sharedInstance.setupConfiguration(apiConfig: apiConfig)
                
                // Set current authorization token in authentication framework
                VLAuthentication.sharedInstance.authorizationToken = self.authorizationToken
                
                // If no token, fetch anonymous token
                if self.authorizationToken == nil {
                    self.authorizationToken = try await VLAuthentication.sharedInstance.apiToGetAnonymousToken()?.authorizationToken
                    VLAuthentication.sharedInstance.authorizationToken = self.authorizationToken
                    
                    try await self.handleTempPass()
                    
                } else if let authorizationToken = self.authorizationToken, let refreshToken = userIdentity?.refreshToken, !authorizationToken.isEmpty && !refreshToken.isEmpty {
                    self.authorizationToken = try await VLAuthentication.sharedInstance
                        .fetchUpdatedAuthToken(
                            refreshToken: refreshToken,
                        )?.authorizationToken
                    
                    VLAuthentication.sharedInstance.authorizationToken = self.authorizationToken
                // If unable to authenticate, log out user
                } else {
                    await self.logoutUser()
                }
            } catch let error as VLAuthenticationErrorCode {
                print("VLAuthentication init error: \(error.codeString)")
            }
        }
    }
    
    func handleTempPass() async throws {
        do {
            let providers = try await VLAuthentication.sharedInstance.getTempPassProvider()
            
            if let id = providers.first?.id {
                let response = try await VLAuthentication.sharedInstance.checkAdobeDecisionsAuthorize(
                    mvpdId: id
                )
                
                switch response {
                case .success(let token):
                    AppDelegate.shared.tempPass = token
                case .failure(let _):
                    AppDelegate.shared.tempPass = nil
                }
            }
        } catch let error as VLAuthenticationErrorCode {
            throw error
        }
    }
    
    // Logs out the user and resets authentication tokens
    func logoutUser() async {
        do {
            // Clear user identity and tokens
            UserManager.shared.userIdentity = nil
            authorizationToken = nil
            VLAuthentication.sharedInstance.authorizationToken = nil
            
            // Fetch and set anonymous token after logout
            self.authorizationToken = try await VLAuthentication.sharedInstance.apiToGetAnonymousToken()?.authorizationToken
            VLAuthentication.sharedInstance.authorizationToken = self.authorizationToken
        } catch {
            print("VLAuthentication init error: \(error.localizedDescription)")
        }
    }
    
    func setupAnalytics() {
        VLAnalytics.shared.setupAnalytics(clients: [.adobe])
    }
}
