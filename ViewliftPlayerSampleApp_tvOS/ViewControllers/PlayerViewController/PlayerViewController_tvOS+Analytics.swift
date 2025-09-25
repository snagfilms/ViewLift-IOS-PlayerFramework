//
//  PlayerViewController_tvOS+Analytics.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLAnalyticsLib
import VLPlayerLib
import AVKit

// Handles analytics integration for player events and content/ad info
extension PlayerViewController_tvOS {
    
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
        let isFullScreen: Bool = false
        
        if let mediaTyp = self.videoResponse?.video?.streamingInfo?.isLiveStream {
            streamType = mediaTyp ? "live" : "vod"
        }
        
        if let monetizationModel = self.videoResponse?.video?.monetizationModels {
            isContentFree = monetizationModel.contains(where: { $0.type == "FREE" })
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
    
    // Tracks the start of video playback for analytics
    func trackVideoStart() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.mediaPlay)
            .contentInfo(getVideoInfo())
            .tvProviderInfo(VLTVProviderInfo(tvProviderName: UserManager.shared.userIdentity?.mvpdProvider,
                                             requestorId:/*requestorId*/ "")
            )
            .adsInfo(getAdsInfo())
            .setPlayer(player)
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func trackAdDidStartsAnalytics() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.adsStart)
            .adsInfo(getAdsInfo())
            .contentInfo(getVideoInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
   
    func trackAdDidCompleteAnalytics() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.adsComplete)
            .adsInfo(getAdsInfo())
            .contentInfo(getVideoInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    
    func trackAdBreakStartAnalytics() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.adsBreakStart)
            .adsInfo(getAdsInfo())
            .contentInfo(getVideoInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func trackAdBreakCompleteAnalytics() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.adsBreakComplete)
            .adsInfo(getAdsInfo())
            .contentInfo(getVideoInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerDidStartPlaying() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.playStarted)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerDidPaused() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videoPauseStarted)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
}

extension PlayerViewController_tvOS: PlayerVideoAnalyticsTrackDelegate{
    func playerDidChangeClosedCaptionLanguage(language: String?) {
        
    }
    
    func updatePlayhead(time: Double) {
        
        let eventBuilder = VLEventModelBuilder()
            .eventType(.updateCurrentPlayHead(time))
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerDidLoadVideo(player: AVPlayer?) {
        let loggedUser = UserManager.shared.userIdentity
        
        let eventBuilder = VLEventModelBuilder()
            .eventType(.mediaPlay)
            .contentInfo(getVideoInfo())
            .tvProviderInfo(VLTVProviderInfo(tvProviderName: loggedUser?.mvpdProvider ?? "", requestorId: /* AppConfiguration.shared.tveSettings?.requestorId*/ "")
            )
            .adsInfo(getAdsInfo())
            .setPlayer(player)
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    
    func playerSeekDidStart(fromTimeInterval: Double) {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videoSeekStarted)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerSeekDidComplete(toTimeInterval: Double) {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videoSeekCompleted)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerSessionEnded() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.trackSessionEnd)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func trackVideoCompletedAnalytics() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videoComplete)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerFirstFrameLoaded() {
        debugPrint("")
    }
    
    func trackVideoFailErrorAnalytics(errorMessage: String) {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.errorEvent)
            .errorMessage(errorMessage)
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerDidChangeAudioLanguage(language: String?) {
        
    }
    
    func playerDidDropFrames(count: Int) {
        
    }
    
    func playerChapterDidStart(currentTime: Double) {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videochapterStart(currentTime))
            .contentInfo(getVideoInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerChapterDidComplete() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videoChapterComplete)
            .adsInfo(getAdsInfo())
            .contentInfo(getVideoInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerDidBitRateChange() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.playerBitrateChanged)
            .adsInfo(getAdsInfo())
            .contentInfo(getVideoInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerDidStartBuffering() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videoBuffer)
            .adsInfo(getAdsInfo())
            .contentInfo(getVideoInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
}
