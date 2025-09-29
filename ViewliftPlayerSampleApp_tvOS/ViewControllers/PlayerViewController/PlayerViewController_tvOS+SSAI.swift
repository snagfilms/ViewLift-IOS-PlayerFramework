//
//  PlayerViewController_tvOS+SSAI.swift
//  ViewliftPlayerSampleApp
//
//  Created by Shivamsharma@viewlift.com on 16/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
import Foundation
import VLAnalyticsLib

/// Extension to handle server-side ad tracking callbacks for the video player.
/// These methods are triggered automatically by `VLPlayerLib` during ad playback events.
extension PlayerViewController_tvOS: ServerSideAdTrackingDelegate {
    func totalAdsDuration(_ duration: Double) {
        self.totalAdsDuration = duration
    }

    
    // MARK: - Auto-triggered (Default + Custom Events)
    
    /// Called when ad cue points (markers for ad breaks) are detected in the content.
    /// - Parameters:
    ///   - adModel: The model containing information about all ads.
    ///   - duration: The total content duration in seconds.
    func adCuePoints(adModel: VLPlayerLib.SSAIAdsModel?, duration: TimeInterval) {
        debugPrint(adModel as Any, duration)
        if let videoPlayerControlsView {
            videoPlayerControlsView.setCuePointsFromPlayer(adModel: adModel, duration: duration)
        }
    }
    
    /// Called when an ad pod (set of ads) starts playing.
    /// - Parameter currentPod: The ad pod that has started.
    func adDidStart(currentPod: VLPlayerLib.SSAIAvailableAds?) {
        // You can display overlays or UI changes here.
        if enableCustomAdUI == true {
            // add Overlay
        }
        // hideControls in order to access Ad view over it
    }
    
    /// Called when the current ad finishes.
    func adDidFinish() {
        // You can remove overlays or reset ad-specific UI here.
    
        if enableCustomAdUI == true {
            // remove overlay
        }
//        trigger ad finish analytics
        // showControls in order to access Player controls
    }
    
    // MARK: - Interactive (Default Controls)
    
    /// Called when the ad's play/pause state changes.
    /// - Parameter isPlaying: `true` if ad is playing, `false` if paused.
    func adPlayPause(isPlaying: Bool) {
        debugPrint(adPlayPause)
    }
    
    /// Called when the ad's fullscreen button is toggled.
    /// - Parameter status: `true` if fullscreen enabled, `false` if disabled.
    func adFullScreenBtnTapped(status: Bool) {
        
    }
    
    /// Called when the ad mute/unmute button is pressed.
    /// - Parameter enabled: `true` if muted, `false` if unmuted.
    func adMuteButton(enabled: Bool) {
        
    }
    
    
    func updateAdPlayback(model: VLPlayerLib.AdModel) {
        debugPrint(model.progress)
        if let ad = model.currentAd, let adId = ad.adId, let analyticsAdInfo = model.analyticsAdInfo {
           self.currentAdAssetInfo = VLAdAssetInfo(
                    adId: analyticsAdInfo.adId,
                    adName: analyticsAdInfo.adName,
                    podName: analyticsAdInfo.podName,
                    podLength: analyticsAdInfo.podLength,
                    podPosition: analyticsAdInfo.podPosition,
                    podOffset: analyticsAdInfo.podOffset, startTime: analyticsAdInfo.startTime, adSystem: analyticsAdInfo.adSystem
                )
            
            AnalyticsHelper.shared.setAdsAssets(adInfo: self.currentAdAssetInfo)
        }
    }
    
    
    // MARK: - Detailed Server-side Tracking Events
    
    /// Handles detailed server-side ad tracking events.
    /// - Parameters:
    ///   - trackingEventType: The type of tracking event (start, complete, pause, etc.).
    ///   - eventTrackingProperties: Additional metadata for the event.
    func serverSideAdTrackingEvents(
        trackingEventType: VLPlayerLib.VLPlayer.AdsEventType,
        eventTrackingProperties: [String : Any]
    ) {
        
        let playerCurrentTime: Double = Double(
            eventTrackingProperties["playerCurrentTime"] as? Double ?? 0.0
        )
        
        switch trackingEventType {
            
        case .breakStart:
            debugPrint("slot impression") // Ad break has started
            
            AnalyticsHelper.shared.trackAdBreakStartAnalytics()
            
        case .impression:
            debugPrint("default impression") // Ad impression logged
            
        case .start:
            debugPrint("impression") // Ad has started playing
            
            AnalyticsHelper.shared.trackAdDidStartsAnalytics()
            
        case .firstQuartile:
            debugPrint("first quartile") // 25% of ad completed
            
        case .midPoint:
            debugPrint("midpoint") // 50% of ad completed
            
        case .thirdQuartile:
            debugPrint("third quartile") // 75% of ad completed
            
        case .complete:
            debugPrint("complete") // 100% of ad completed
            
            AnalyticsHelper.shared.trackAdDidCompleteAnalytics()
            
        case .breakEnd:
            debugPrint("slot end") // Ad break has ended
            
            
            if let startTime = self.vlPlayer?.getCurrentPlaybackTime(), let endTime = self.vlPlayer?.getChapterEndTime() {
                
                AnalyticsHelper.shared
                    .trackAdBreakCompleteAnalytics(
                        playerCurrentTime: startTime,
                        chapterEnd: endTime
                    )
            }
            
        case .mute:
            debugPrint("mute") // Ad muted
            
        case .unmute:
            debugPrint("unmute") // Ad unmuted
            
        case .exitFullscreen:
            debugPrint("exit full screen") // Ad exited fullscreen
            
        case .fullscreen:
            debugPrint("fullscreen") // Ad entered fullscreen
            
        case .resume:
            debugPrint("resume") // Ad resumed after pause
            
            AnalyticsHelper.shared.playerDidStartPlaying()
            
        case .closeLinear:
            debugPrint("close") // Linear ad closed
            
        case .error:
            debugPrint("error") // Ad playback error
            
        case .pause:
            debugPrint("pause") // Ad paused
            
            AnalyticsHelper.shared.playerDidPaused()
            
        case .acceptInvitationLinear:
            debugPrint("accept invitation") // User accepted invitation ad
            
        case .rewind:
            debugPrint("rewind") // Ad rewinded
            
        case .creativeView:
            debugPrint("creative view") // Creative view tracked
            
        case .stop:
            debugPrint("stop") // Ad stopped before completion
            
        case .clickThrough:
            debugPrint("clickThrough") // User clicked through ad
            
        case .clickTracking:
            debugPrint("clickTracking") // Click tracking logged
            
        case .collapse:
            debugPrint("collapse") // Ad collapsed from expanded state
            
        case .expand:
            debugPrint("expand") // Ad expanded
            
        case .none:
            debugPrint("none") // No tracking event
            
        @unknown default:
            debugPrint("default") // Future-proof: unknown event
        }
    }
}
