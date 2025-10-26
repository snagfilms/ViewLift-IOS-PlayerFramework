//
//  AnalyticsHelper+Data.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 26/09/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import VLAnalyticsLib
import UIKit

extension AnalyticsHelper {
    private func getUserinfo() -> VLUserInfo? {
        guard let userInfo = UserManager.shared.userIdentity else { return nil }
        
        return VLUserInfo(
            userId: userInfo.userId, email: userInfo.email, deviceID: UIDevice.current.identifierForVendor?.uuidString
        )
    }
    
    internal func getTVEProviderInfo() -> VLTVProviderInfo? {
        guard let userInfo = UserManager.shared.userIdentity else { return nil }
        
        return VLTVProviderInfo(
            tvProviderName: userInfo.mvpdProvider,
            requestorId: resourceID, tveID: userInfo.tveUserId)
    }
    
    internal func getAppInfo() -> VLAppInfo {
        return VLAppInfo(
            network: AnalyticsHelper.shared.reachability.getRechabilityStatus(),
            publisher: orgid,
            domain: domain
        )
    }
    
    internal func getPlayerInfo() -> VLPlayerInfo {
        return VLPlayerInfo(
            playerTech: "AVPlayer Viewlift",
            playerName: "AVPlayer",
            playerVersion: "3.0.0"
        )
    }
    
    func handleTrackEvent(eventData: VLEventModel) {
        var tempEventData = eventData
        tempEventData.appInfo = getAppInfo()
        tempEventData.tvProviderInfo = getTVEProviderInfo()
        tempEventData.playerInfo = getPlayerInfo()
        
        tempEventData.contentInfo?.networkType = "On-Domain"
        
        VLAnalytics.shared.trackEvent(data: tempEventData)
    }
}
