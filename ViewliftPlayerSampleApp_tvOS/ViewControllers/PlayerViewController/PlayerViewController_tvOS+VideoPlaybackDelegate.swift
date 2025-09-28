//
//  PlayerViewController_tvOS+VideoPlaybackDelegate.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
import AVKit
import VLAuthentication
import Foundation
import VLAnalyticsLib

// Handle video playback delegate events for the player view controller
extension PlayerViewController_tvOS: VideoPlaybackDelegate {
    
    func onFullScreenChange(currentTime: Double, isFullScreen: Bool, playerTag: String) {
        debugPrint("onFullScreenChange: currentTime: \(currentTime), isFullScreen: \(isFullScreen), playerTag: \(playerTag)")
        testButton.isHidden = isFullScreen
        changeLayout()
    }
    
    func videoPlaybackError(currentTime: Double, errorMessage: String, errorCode: String, playerTag: String) {
        DispatchQueue.main.async { [weak self] in
            if let playerView = self?.vlPlayer?.getVideoPlayerView(){
                self?.errorHandler(message: errorMessage, playerView: playerView)
            }
        }
    }
    
    private func errorHandler(message: String, playerView: UIView) {
        let errorLabel = UILabel()
        errorLabel.text = "Video playback failed"
        errorLabel.textColor = .white
        errorLabel.textAlignment = .center
        errorLabel.font = .systemFont(ofSize: 32, weight: .medium)
        errorLabel.numberOfLines = 0
        errorLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        errorLabel.layer.cornerRadius = 8
        errorLabel.clipsToBounds = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        playerView.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: playerView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: playerView.trailingAnchor, constant: -20)
        ])
    }

    
    // Handles errors during video fetch and updates UI accordingly
    func videoFetchError(error: VLError?, playerTag: String?, contentResponse: Dictionary<String, AnyObject>?) {
        let errorDescription =  "Is content playable - \(error?.isPlayable ?? false) \n" +
        "Content Fetched successfully - \(error?.isSuccess ?? false) \n" +
        "Error Code - \(error?.errorCode ?? "errorCode") \n" +
        "Error Message - \(error?.errorMessage ?? "errorMessage") \n" +
        "Error VL Code - \(error?.vl_errorCode ?? "errorVLCode")"
        
        print("Error VL:", errorDescription)
        print("VideoFetchError: contentResponse:", contentResponse)
        
        if error?.errorCode == "TVE_SUBSCRIPTION_NOT_FOUND"{// handle other TVE error code too
            loginWithTVE()
        } else {
            DispatchQueue.main.async {
                self.showAlert(message: errorDescription)
                self.customPaywallView?.update(error?.errorMessage ?? "Error occurred while fetching content")
            }
        }
        
    }
    
    // Updates play/pause state in custom controls
    func customPlayerState(isPlaying: Bool) {
        videoPlayerControlsView?.playPause(isPlaying: isPlaying)
        
        if isPlaying {
            AnalyticsHelper.shared.playerDidStartPlaying()
        } else {
            AnalyticsHelper.shared.playerDidPaused()
        }
    }
    
    // Called when subtitle embedding in URL changes
    func isSubtitlesEmbeddedInUrlChanged(isEmbedded: Bool) {
        debugPrint("PlayerViewController isSubtitlesEmbeddedInUrlChanged: \(isEmbedded)")
    }
 
    func videoFinished(playerTag: String) {
        AnalyticsHelper.shared.trackVideoCompletedAnalytics()
    }
    
    // Called when custom player controls visibility changes
    func customPlayerControls(isHidden: Bool) {
        print("PlayerViewController customPlayerControls: \(isHidden)")
        if isHidden{
            videoPlayerControlsView?.customPlayerControls(isHidden: isHidden)
        }
    }
    
    // Called when video playback starts
    func videoStarted(timestamp: Double, playerTag: String) {
        videoPlayerControlsView?.videoStartedPlaying(timestamp: timestamp)
        debugPrint("PlayerViewController videoStarted: \(timestamp)")
        
        self.videoSessionStartAnalytics()
        
    }
    
    func videoPause(timestamp: Double, playerTag: String) {
        AnalyticsHelper.shared.playerDidPaused()
    }

    func videoResume(timestamp: Double, playerTag: String) {
        if VLAnalytics.shared.isMediaSessionTracked == false {
            self.videoSessionStartAnalytics()
        } else {
            AnalyticsHelper.shared.playerDidStartPlaying()
        }
    }

    
    func videoSessionStartAnalytics() {
        let isPreRollAds = self.vlPlayer?.isVideoHavingPreRollAds() ?? false
        let currentPlaybackTime = self.vlPlayer?.getCurrentPlaybackTime() ?? 0.0
        let endPlaybackTime = self.vlPlayer?.getChapterEndTime() ?? 0.0
        
        let chapterInfo = ChapterInfoModel(
            havingPreRollAds: isPreRollAds,
            startTime: currentPlaybackTime,
            endTime: endPlaybackTime
        )
        
        if let contentInfo = self.getVideoInfo() {
            AnalyticsHelper.shared.triggerVideoSessionStartEvent(contentInfo: contentInfo,chapterInfo: chapterInfo)
        }
    }
    
    // Updates playback progress every second
    func videoPlayerProgressByEverySecond(currentTime: Double, totalTime: Double, playerTag: String, parsedTimeStamp: String?) {
       // debugPrint("PlayerViewController videoPlayerProgressByEverySecond: \(currentTime), \(totalTime)")
        videoPlayerControlsView?.updateCurrentTime(currentTime: currentTime, totalTime: totalTime)
        
        self.invalidatePlayerTempPassIfOutOfWindow()
    }
    
    // Updates playback progress at specific intervals
    func videoPlayerUpdateByProgressInterveral(currentTime: Double, totalTime: Double, playerTag: String) {
        debugPrint("PlayerViewController videoPlayerUpdateByProgressInterveral]ssByEverySecond: \(currentTime), \(totalTime)")
        videoPlayerControlsView?.updateCurrentTime(currentTime: currentTime, totalTime: totalTime)
    }
    
    // Handles back button tap event
    func onBackButtonTapped() {
        menuPressed()
    }
    
    func avPlayerControllerInstance(_ avPlayerControllerInstance: AVPlayerViewController) {
        avPlayerControllerInstance.delegate = self
    }
}

extension PlayerViewController_tvOS: AVPlayerViewControllerDelegate {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willResumePlaybackAfterUserNavigatedFrom oldTime: CMTime, to targetTime: CMTime) {
        debugPrint("willResumePlaybackAfterUserNavigatedFrom: oldTime: \(oldTime), targetTime: \(targetTime)")
    }
    
}
