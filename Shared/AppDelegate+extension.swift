//
//  AppDelegate+extension.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 04/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import UIKit
#if os(iOS)
import VLAuthenticationFramework
#else
import VLAuthenticationFramework_tvOS
#endif

extension AppDelegate {
    static var shared: AppDelegate {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Could not cast UIApplication delegate as AppDelegate")
        }
        return delegate
    }
    
    func setupAuthentication() {
        // Get current user identity before async context
        let userIdentity = UserManager.shared.userIdentity
        self.authorizationToken = userIdentity?.authorizationToken

        let apiConfig = APIConfig(
            xApiKey: xApiKey,
            siteId: siteId,
            authorizationToken: authorizationToken,
            apiBaseUrl: apiBaseEndpoint,
            graphQLApiBaseUrl: graphQLEndpoint
        )

        Task { [weak self] in
            do {
                guard let self = self else { return }
                
                try await VLAuthentication.sharedInstance.setupConfiguration(apiConfig: apiConfig)

                VLAuthentication.sharedInstance.authorizationToken = self.authorizationToken
                
                if self.authorizationToken == nil {
                    self.authorizationToken = try await VLAuthentication.sharedInstance.apiToGetAnonymousToken()?.authorizationToken
                    VLAuthentication.sharedInstance.authorizationToken = self.authorizationToken
                    
                } else if let authorizationToken = self.authorizationToken, !authorizationToken.isEmpty && isJWTExpired(authorizationToken) {
                    await self.logoutUser()
                }
            } catch {
                print("VLAuthentication init error: \(error.localizedDescription)")
            }
        }
    }
    
    func logoutUser() async {
        do {
            UserManager.shared.userIdentity = nil
            authorizationToken = nil
            VLAuthentication.sharedInstance.authorizationToken = nil
            
            self.authorizationToken = try await VLAuthentication.sharedInstance.apiToGetAnonymousToken()?.authorizationToken
            VLAuthentication.sharedInstance.authorizationToken = self.authorizationToken
        } catch {
            print("VLAuthentication init error: \(error.localizedDescription)")
        }
    }
}
