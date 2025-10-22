//
//  ChapterInfoModel.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 19/10/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//


import VLPlayerLib
import AVKit
import Foundation
#if os(iOS)
import VLAuthenticationFramework
#else
import VLAuthenticationFramework_tvOS
#endif

final class AnalyticsHelperV2: NSObject {
    // MARK: Singleton
    static let shared = AnalyticsHelperV2()
    
    let domain = "https://spinco.staging.web.viewlift.com"
    let orgid = "8CF467C25245AE3F0A490D4C@AdobeOrg"
    let resourceID = "sparkmedia"
    var requestorId = "sparkmedia"
    
    private override init() {
        super.init()
    
    }
    
    internal func getTVEProviderInfo() -> VLTVProviderInfoAnalytics? {
        guard let userInfo = UserManager.shared.userIdentity else { return nil }
        
        return VLTVProviderInfoAnalytics(
            tvProviderName: userInfo.mvpdProvider,
            requestorId: resourceID, tveID: userInfo.tveUserId)
    }
    
    internal func getPlayerInfo() -> AnalyticsPlayerInfo {
        return AnalyticsPlayerInfo(
            playerVersion: "3.0.0", publisher: orgid,
        )
    }

}
