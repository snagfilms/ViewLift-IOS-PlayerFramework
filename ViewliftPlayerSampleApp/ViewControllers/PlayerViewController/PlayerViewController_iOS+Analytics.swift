//
//  PlayerViewController_iOS+Analytics.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLAnalyticsLib
import VLPlayerLib
import AVKit

// Handles analytics integration for player events and content/ad info
extension PlayerViewController_iOS: VLAnalyticsPlayerClientProtocol {
    // Called when the player starts playback
    func trackVideoStartAnalytics() {
        
        let eventBuilder = VLEventModelBuilder()
            .eventType(.playStarted)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func trackVideoPauseAnalytics() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videoPauseStarted)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    // Stores current ad asset info for analytics
    func setAdInfo(adId: String, adName: String, podName: String?, podLength: Double?, podPosition: Int?, podOffset: Double?, startTime: Double?, adSystem: String?) {
        self.currentAdAssetInfo = VLAdAssetInfo(adId: adId, adName: adName, podName: podName, podLength: podLength, podPosition: podPosition, podOffset: podOffset, startTime: startTime, adSystem: adSystem)
    }
    
    // Clears ad asset info when ad completes
    func setAdComplete() {
        self.currentAdAssetInfo = nil
    }
    
    // Returns current ad asset info for analytics
    func getAdsInfo() -> VLAdAssetInfo? {
        return self.currentAdAssetInfo
    }
    
    // Parses video response dictionary and decodes to model
    func parseVLVideoResponse(from dictionary: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            let response = try decoder.decode(VLVideoResponseModel.self, from: jsonData)
            self.videoResponse = response
        } catch {
            print("❌ Failed to decode from dictionary:", error)
        }
    }
    
    // Formats a timestamp into a date string
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
    
    // Builds and returns video content info for analytics
    func getVideoInfo() -> VLContentInfo? {
        var streamType: String = ""
        var isContentFree: Bool = false
        var isFullScreen: Bool = false
        
        if let mediaTyp = self.videoResponse?.video?.streamingInfo?.isLiveStream {
            streamType = mediaTyp ? "live" : "vod"
        }

        if let monetizationModel = self.videoResponse?.video?.monetizationModels {
            isContentFree = monetizationModel.contains(where: { $0.type == "FREE" })
        }
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            isFullScreen = appDelegate.isFullScreen
        }
        
        let data = self.videoResponse?.video
        let isFree = !(self.videoResponse?.plans?.isEmpty ?? false) && isContentFree
        let status = isFree ? "free" : "premium"
        let videobroadcast = self.videoResponse?.video?.streamingInfo?.isLiveStream ?? false ? "Broadcast" : "Digital"

        return VLContentInfo(
            id: data?.id,
            title: data?.title,
            seriesTitle: data?.title,
            contentType: streamType,
            airDate: self.getFormattedDateFromTimestamp(timestamp: self.videoResponse?.video?.publishDate),
            streamType: streamType,
            screenSize: isFullScreen ? "FullScreen" : "Normal",
            videostatus: status,
            videotmsid: data?.id,
            videobroadcast: videobroadcast,
            videoInitiate: "Manual"
        )
    }
}
