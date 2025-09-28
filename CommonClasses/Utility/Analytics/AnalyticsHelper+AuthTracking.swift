//
//  AnalyticsHelper+AuthTracking.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 27/09/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLAuthentication
import VLAnalyticsLib

extension AnalyticsHelper: AuthenticationAnalyticsDelegate {
    func tveProviderSignIn(mvpd: String) {
        let userInfo = VLUserInfo(contentHub: "Adobe Pass",
                                  passNetwork: self.requestorId,
                                  passMvpd: mvpd)
        self.triggerAnalytics(event: .providerSignIn, userInfo: userInfo)
    }
    
    func tveProviderSignInSuccess(mvpd: String) {
        let userInfo = VLUserInfo(contentHub: "Adobe Pass",
                                  passNetwork: self.requestorId,
                                  passMvpd: mvpd)
        self.triggerAnalytics(event: .tveLoginSuccess, userInfo: userInfo)
    }
    
    func tveProviderSignInFailure(mvpd: String) {
        let userInfo = VLUserInfo(contentHub: "Adobe Pass",
                                  passNetwork: self.requestorId,
                                  passMvpd: mvpd)
        self.triggerAnalytics(event: .tveLoginFailure, userInfo: userInfo)
    }

    func tveProviderLandingPageTapped() {
        self.triggerAnalytics(event: .providerLanding)
    }
    
    func tveOpenMvpdSelected() {
        self.triggerAnalytics(event: .openMvpdSelector)
    }
    
    func tveChooseAlternateProviderSelected() {
        self.triggerAnalytics(event: .chooseAlternateProvider)
    }
    
    func tveProviderSelected(adobe: AdobeMvpd) {
        let userInfo = VLUserInfo(contentHub: "Adobe Pass",
                                  passNetwork: self.requestorId,
                                  passMvpd: adobe.id)
        self.triggerAnalytics(event: .tveProviderSelected, userInfo: userInfo)
    }
}
