//
//  AnalyticsProtocol.swift
//  ViewliftPlayerSampleApp
//
//  Created by ViewLift on 03/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import Foundation
import VLPlayerLib
import VLAnalyticsLib
import AVFoundation

public protocol VLAnalyticsPlayerClientProtocol: PlayerVideoAnalyticsTrackDelegate, PlayerAdsAnalyticsTrackDelegate {
    func playerDidLoadVideo(player: AVPlayer?) //using
    func playerFirstFrameLoaded() //using
    func playerSeekDidStart(fromTimeInterval: Double) //using
    func playerSeekDidComplete(toTimeInterval: Double) //using
    func playerSessionEnded() //using
    func playerDidChangeAudioLanguage(language: String?) //using
    func playerDidChangeClosedCaptionLanguage(language: String?) //using
    func playerDidDropFrames(count: Int) //using
    func playerDidStartBuffering() //using
    func playerDidBitRateChange() //using
    
    func updatePlayhead(time: Double)
    func playerChapterDidStart() //using. currently its being call when video is completed. handle when ads break stop
    func playerChapterDidComplete() //using. currently its being call when video is completed. handle when ads break starts
    
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
