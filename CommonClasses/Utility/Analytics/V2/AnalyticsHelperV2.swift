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
    
        VLAuthentication.sharedInstance.analyticsDelegate = self
    }
    
    internal func getTVEProviderInfo() -> VLTVProviderInfoAnalytics? {
        guard let userInfo = UserManager.shared.userIdentity else { return nil }
        
        return VLTVProviderInfoAnalytics(
            tvProviderName: userInfo.mvpdProvider,
            requestorId: resourceID, tveID: userInfo.tveUserId)
    }
    
    internal func getPlayerInfo() -> AnalyticsPlayerInfo {
        return AnalyticsPlayerInfo(
            playerVersion: "3.0.0",
            playerName: "AVPlayer VL",
            playerTech: "AVPlayer",
            publisher: AnalyticsHelperV2.shared.orgid
        )
    }

}


extension AnalyticsHelperV2 {
    @discardableResult
    func parseVLVideoResponse(from dictionary: [String: Any]) -> VLVideoResponseModel? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            let response = try Self.decoder.decode(VLVideoResponseModel.self, from: jsonData)
            return response
        } catch {
            print("❌ Failed to decode from dictionary:", error)
            return nil
        }
    }
    
    func getFormattedDateFromTimestamp(timestamp: TimeInterval?) -> String? {
        guard let timestamp = timestamp else {
            return nil
        }
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.timeZone = .current
        let formattedDate = formatter.string(from: date)
        print("Publish Date: \(formattedDate)")
        return formattedDate
    }
}

private extension AnalyticsHelperV2 {
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .useDefaultKeys
        return d
    }()

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy"
        f.timeZone = .current
        return f
    }()

    static func dateMMDDYYYY(from timestamp: TimeInterval?) -> String? {
        guard let ts = timestamp else { return nil }
        return dateFormatter.string(from: Date(timeIntervalSince1970: ts))
    }
}
