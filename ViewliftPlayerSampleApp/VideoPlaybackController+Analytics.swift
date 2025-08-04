//
//  VideoPlaybackController+Analytics.swift
//  ViewliftPlayerSampleApp
//
//  Created by Nexgen on 03/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import Foundation
import VLPlayerLib
import VLAnalyticsLib
import AVFoundation

public protocol VLAnalyticsPlayerClientProtocol: PlayerVideoAnalyticsTrackDelegate, PlayerAdsAnalyticsTrackDelegate {
    func playerDidLoadVideo(player: AVPlayer?)
    func playerFirstFrameLoaded()
    func playerDidStart()
    func playerDidPause()
    func playerSeekDidStart()
    func playerSeekDidComplete()
    func playerDidEnded()
    func playerDidComplete()
    func playerDidFail(errorMessage: String, isFatal: Bool)
    func playerDidChangeAudioLanguage(language: String?)
    func playerDidChangeClosedCaptionLanguage(language: String?)
    func playerDidDropFrames(count: Int)
    func playerChapterDidStart()
    func playerChapterDidComplete()
    func playerDidStartBuffering()
    func playerDidBitRateChange()
    func updatePlayhead(time: Double)
    
    
    func setAdInfo(adId: String, adName: String, podName: String?, podLength: Double?, podPosition: Int?, podOffset: Double?, startTime: Double?, adSystem: String?)
    func setAdComplete()
    
    func adDidStarts()
    
    func adDidPause()
    func adsDidLoad()
    func adDidComplete()
    func adBreakStarts()
    func adBreakComplete()
    
    func getVideoInfo() -> VLContentInfo?
    func getAdsInfo() -> VLAdAssetInfo?

}

// MARK: - Protocol Extension with Default Implementations
extension VLAnalyticsPlayerClientProtocol {
    
    func updatePlayhead(time: Double) {
        let videoInfo = self.getVideoInfo()
        videoInfo?.playbackPositionInSeconds = time
       
        let eventBuilder = VLEventModelBuilder()
            .eventType(.updateCurrentPlayHead)
            .contentInfo(videoInfo)
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerDidLoadVideo(player: AVPlayer?) {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.mediaPlay)
            .contentInfo(getVideoInfo())
            .tvProviderInfo(VLTVProviderInfo(tvProviderName: /*ParentalControlHelper.getUserDetails()?.mvpdProvider*/ "",
                                             requestorId:/* AppConfiguration.shared.tveSettings?.requestorId*/ "")
            )
            .adsInfo(getAdsInfo())
            .setPlayer(player)
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerDidStart() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.playStarted)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerDidPause() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videoPauseStarted)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerSeekDidStart() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videoSeekStarted)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerSeekDidComplete() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videoSeekCompleted)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerDidEnded() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.trackSessionEnd)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerDidComplete() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videoComplete)
            .contentInfo(getVideoInfo())
            .adsInfo(getAdsInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func playerFirstFrameLoaded() {
        
    }
    
    func playerDidFail(errorMessage: String, isFatal: Bool) {
        
    }
    
    func playerDidChangeAudioLanguage(language: String?) {
        
    }
    
    func playerDidChangeClosedCaptionLanguage(language: String?) {
        
    }
    
    func playerDidDropFrames(count: Int) {
        
    }
    
    func playerChapterDidStart() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videochapterStart)
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
    
    func adDidStarts() {
        
        let eventBuilder = VLEventModelBuilder()
            .eventType(.adsStart)
            .adsInfo(getAdsInfo())
            .contentInfo(getVideoInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func adsDidLoad() {
        
    }
    
    func adDidPause() {
        
    }
    
    func adDidComplete() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.adsComplete)
            .adsInfo(getAdsInfo())
            .contentInfo(getVideoInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    
    func adBreakStarts() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.adsBreakStart)
            .adsInfo(getAdsInfo())
            .contentInfo(getVideoInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
    
    func adBreakComplete() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.adsBreakComplete)
            .adsInfo(getAdsInfo())
            .contentInfo(getVideoInfo())
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
}
