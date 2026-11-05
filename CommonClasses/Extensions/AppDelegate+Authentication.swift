//
//  AppDelegate+Authentication.swift
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
import VLAnalyticsLib
//import Firebase

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
        self.authorizationToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb3VudHJ5Q29kZSI6IlVTIiwiZGV2aWNlSWQiOiJGNTIxNUY3Mi0wOEE0LTQ2MzctOTUyMS1BQjA4NzI1MzlFNTQiLCJlbWFpbCI6ImRjYzhkMjAzLWJmODEtNDdhOS1hMjU0LWE4NGVhY2ExNzAyNy1hdXRvQHZpZXdsaWZ0LmNvbSIsImV4cCI6MTc5NjI5OTYzMCwiaWF0IjoxNzkzNzA3NjMwLCJpZCI6ImRjYzBkMDRmLThjODQtNGRkYS04ZTU0LWU1MmFmZDhiNjhiNyIsImlwYWRkcmVzc2VzIjoiMTg3LjE1LjkxLjIzNCwxMC4yMDEuMTkzLjIwNCIsInBvc3RhbGNvZGUiOiI5ODE2MCIsInByb3ZpZGVyIjoiaG90d2lyZWNvbW11bmljYXRpb25zX2F1dGgtZ2F0ZXdheV9uZXQiLCJzaXRlIjoiZ29sZmNoYW5uZWwiLCJzaXRlSWQiOiI4YjQxMzVmNi0zZjU5LTQyOGQtYWUyNy04YzllMjcwNjQxMTIiLCJ1c2VySWQiOiJkY2MwZDA0Zi04Yzg0LTRkZGEtOGU1NC1lNTJhZmQ4YjY4YjcifQ.J51Zsdkdtt8q0mAzrdXDwRTdD5AnB5ThBiRciT_11tg"//userIdentity?.authorizationToken
        
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
//        #if os(iOS)
//        VLAuthentication.sharedInstance.setRedirectURLForAdobe("https://valid.redirect.url")
//        #endif
        
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
                    
                } else if let authorizationToken = self.authorizationToken, let refreshToken = userIdentity?.refreshToken, !authorizationToken.isEmpty && !refreshToken.isEmpty {
                    self.authorizationToken = try await VLAuthentication.sharedInstance
                        .fetchUpdatedAuthToken(
                            refreshToken: refreshToken
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
    
    func setupAnalyticsConfiguration() {
        let adobeConfig = AdobeAnalyticsConfig(
//            reportSuites: "rsid1,rsid2",
//            trackingServer: "tracking.server.com",
            environmentKey: "77ca722dd820/99867d0bb529/launch-a88516d7f021-development"
        )
        
//        let comscoreConfig = ComscoreAnalyticsConfig(
//            publisherId: "",
//            enableDebugMode: true
//        )
        
        let results = AnalyticsConfigurationBuilder()
            .add(adobeConfig)
//            .add(comscoreConfig)
            .build()
        
        // Check results
        results.forEach { client, success in
            print("\(client.identifier): \(success ? "✅" : "❌")")
        }
    }
    
    func setupAnalytics() {
        self.setupAnalyticsConfiguration()
        
        VLAnalytics.shared.setupAnalytics(clients: [.adobe], enableDebugLogs: true)
        self.handleAnalyticsConsent()
        
        self.triggerSpashScreenEvent()
        
        VLAnalytics.shared.startObservingPlayerEvents()
    }
    
    func handleAnalyticsConsent() {
        VLAnalytics.shared.setConsent(
                                analyticsStorageIsAllowed: true,
                                adStorageIsAllowed: true,
                                adUserDataIsAllowed: true
        )
    }
    
    func triggerSpashScreenEvent() {
        AnalyticsHelperV2.shared.triggerAnalytics(event: .splashEvent)
    }
}
