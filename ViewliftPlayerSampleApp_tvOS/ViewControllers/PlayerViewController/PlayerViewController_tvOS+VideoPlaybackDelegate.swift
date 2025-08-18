//
//  PlayerViewController_tvOS+VideoPlaybackDelegate.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
#if os(iOS)
import VLAuthenticationFramework
#else
import VLAuthenticationFramework_tvOS
#endif
import Foundation

// Handle video playback delegate events for the player view controller
extension PlayerViewController_tvOS: VideoPlaybackDelegate {
    
    // Handles errors during video fetch and updates UI accordingly
    func videoFetchError(error: VLError?, playerTag: String?, contentResponse: Dictionary<String, AnyObject>?) {
        let errorDescription =  "Is content playable - \(error?.isPlayable ?? false) \n" +
        "Content Fetched successfully - \(error?.isSuccess ?? false) \n" +
        "Error Code - \(error?.errorCode ?? "errorCode") \n" +
        "Error Message - \(error?.errorMessage ?? "errorMessage") \n" +
        "Error VL Code - \(error?.vl_errorCode ?? "errorVLCode")"
        
        print("Error VL:", errorDescription)
        print("VideoFetchError: contentResponse:", contentResponse)
        DispatchQueue.main.async {
            self.showAlert(message: errorDescription)
            self.customPaywallView?.update(error?.errorMessage ?? "Error occurred while fetching content")
        }
    }
    
    // Updates play/pause state in custom controls
    func customPlayerState(isPlaying: Bool) {
        videoPlayerControlsView?.playPause(isPlaying: isPlaying)
    }
    
    // Called when subtitle embedding in URL changes
    func isSubtitlesEmbeddedInUrlChanged(isEmbedded: Bool) {
        debugPrint("PlayerViewController isSubtitlesEmbeddedInUrlChanged: \(isEmbedded)")
    }
    
    // Called when video finishes playing
    func didFinishPlaying() {
        print("PlayerViewController didFinishPlaying")
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
    }
    
    // Updates playback progress every second
    func videoPlayerProgressByEverySecond(currentTime: Double, totalTime: Double, playerTag: String, parsedTimeStamp: String?) {
        debugPrint("PlayerViewController videoPlayerProgre]ssByEverySecond: \(currentTime), \(totalTime)")
        videoPlayerControlsView?.updateCurrentTime(currentTime: currentTime, totalTime: totalTime)
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
}
