//
//  PlayerViewController_iOS+VideoPlaybackDelegate.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
import Foundation
import GoogleCast
import VLAnalyticsLib

// Handles video playback delegate events for the player view controller
extension PlayerViewController_iOS: VideoPlaybackDelegate {

    // Called when video playback starts
    func videoStarted(timestamp: Double, playerTag: String) {
        videoPlayerControlsView?.setPlayButtonState(state: true)
        videoPlayerControlsView?.updateTimeLabelOnStart()

        videoPlayerCustomView?.viewModel?.updatePlayingState(isPlaying: true)
        if let currentTime = vlPlayer?.getCurrentTime(), let remainingTime = vlPlayer?.getCurrentVideoTimeLeft() {
            videoPlayerCustomView?.viewModel?.updateTimeLabel(totalTime: remainingTime, currentTime: currentTime)
        }
        videoPlayerCustomView?.viewModel?.setupPiP()

        self.playerDidStartPlaying()
    }

    // Called when video is paused
    func videoPause(timestamp: Double, playerTag: String) {
        videoPlayerControlsView?.setPlayButtonState(state: false)
        videoPlayerCustomView?.viewModel?.updatePlayingState(isPlaying: false)

    }

    // Called when video resumes from pause
    func videoResume(timestamp: Double, playerTag: String) {
        videoPlayerControlsView?.setPlayButtonState(state: true)
        videoPlayerCustomView?.viewModel?.updatePlayingState(isPlaying: true)
    }

    // Called when video finishes playback
    func videoFinished(playerTag: String) {
        videoPlayerControlsView?.setPlayButtonState(state: false)
        videoPlayerCustomView?.viewModel?.updatePlayingState(isPlaying: false)

        self.trackVideoCompletedAnalytics()
    }

    // Handles playback errors and shows alert if needed
    func videoPlaybackError(currentTime: Double, errorMessage: String, errorCode: String, playerTag: String) {
        videoPlayerControlsView?.setPlayButtonState(state: false)
        videoPlayerCustomView?.viewModel?.updatePlayingState(isPlaying: false)

        if !errorMessage.isEmpty {
            showAlert(message: errorMessage)

            self.trackVideoFailErrorAnalytics(errorMessage: errorMessage)
        }
    }

    // Handles errors during video fetch and updates UI accordingly
    func videoFetchError(error: VLError?, playerTag: String?, contentResponse: Dictionary<String, AnyObject>?) {
        let errorDescription = buildErrorDescription(from: error)

        print("Error VL:", errorDescription)
        print("VideoFetchError: contentResponse:", contentResponse as Any)

        DispatchQueue.main.async { [weak self] in
            self?.showAlert(message: errorDescription)
            self?.customPaywallView?.update(error?.errorMessage ?? "Error occurred while fetching content")
        }
    }

    // Builds a detailed error description string from VLError
    private func buildErrorDescription(from error: VLError?) -> String {
        guard let error = error else { return "Unknown error occurred" }

        return """
        Is content playable - \(error.isPlayable)
        Content Fetched successfully - \(error.isSuccess)
        Error Code - \(error.errorCode)
        Error Message - \(error.errorMessage)
        Error VL Code - \(error.vl_errorCode)
        """
    }

    // Called every second to update playback progress and UI
    func videoPlayerProgressByEverySecond(currentTime: Double, totalTime: Double, playerTag: String, parsedTimeStamp: String?) {
        let elapsedTime = calculateElapsedTime(currentTime: currentTime, totalTime: totalTime)

        videoPlayerControlsView?.updateTimeLabel(
            timeRemaining: totalTime - currentTime,
            elapsedTime: currentTime
        )
        videoPlayerCustomView?.viewModel?.updateTimeLabel(totalTime: (totalTime - currentTime), currentTime: currentTime)

        let sliderValue = getSliderDuration(currentTime: elapsedTime, totalDuration: totalTime)
        videoPlayerControlsView?.updateSliderDuration(sliderValue: sliderValue)
        videoPlayerCustomView?.viewModel?.seekTo(time: sliderValue)
    }

    // Calculates elapsed time, considering start-over if available
    private func calculateElapsedTime(currentTime: Double, totalTime: Double) -> Double {
        guard let _ = vlPlayer.getStartOverTime() else { return currentTime }
        return currentTime > totalTime ? totalTime : currentTime
    }

    // Calculates slider value for progress bar
    private func getSliderDuration(currentTime: Double, totalDuration: Double) -> Double {
        guard totalDuration > 0, currentTime <= totalDuration else { return 0 }
        return currentTime / totalDuration
    }

    // Appends bitrate debug logs to the debug view if enabled
    func playerBitrateDebugLogs(logString: String) {
        guard enableBitrateLogs else { return }

        debugLogView.isHidden = false
        debugLogView.text.append(logString + "\n\n")

        let range = NSRange(location: debugLogView.text.count - 1, length: 0)
        debugLogView.scrollRangeToVisible(range)
    }

    //GoogleCasting Delegate
    func chromeCastConnectionStatusUpdate(isConnected: Bool, castContextSessionInstance: GCKCastContext?) {
        AppDelegate.shared.isCastingViewVisible = isConnected
        AppDelegate.shared.castContextSharedInstance = castContextSessionInstance
    }

}
