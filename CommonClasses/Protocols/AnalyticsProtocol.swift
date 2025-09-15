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

public protocol VLAnalyticsPlayerClientProtocol: PlayerVideoAnalyticsTrackDelegate {
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
    func playerChapterDidStart(currentTime: Double)
    func playerChapterDidComplete() //using.
    
    func getVideoInfo() -> VLContentInfo?
    func getAdsInfo() -> VLAdAssetInfo?

}

// MARK: - Protocol Extension with Default Implementations
extension VLAnalyticsPlayerClientProtocol {
    
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
    
    func playerChapterDidStart(currentTime: Double) {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.videochapterStart(currentTime, 10.5))
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
