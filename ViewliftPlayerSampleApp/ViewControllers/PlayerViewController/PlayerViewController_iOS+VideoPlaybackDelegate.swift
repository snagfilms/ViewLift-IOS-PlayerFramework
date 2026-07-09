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
import AVFoundation

// Handles video playback delegate events for the player view controller
extension PlayerViewController_iOS: VideoPlaybackDelegate {

    // Called when video playback starts
    func videoStarted(timestamp: Double, playerTag: String, metaDataInfo: [String : Any]?) {
        videoPlayerControlsView?.setPlayButtonState(state: true)
        videoPlayerControlsView?.updateTimeLabelOnStart()

        videoPlayerCustomView?.viewModel?.updatePlayingState(isPlaying: true)
        if let currentTime = vlPlayer?.getCurrentTime(), let remainingTime = vlPlayer?.getCurrentVideoTimeLeft() {
            videoPlayerCustomView?.viewModel?.updateTimeLabel(totalTime: remainingTime, currentTime: currentTime)
        }
        videoPlayerCustomView?.viewModel?.setupPiP()
        
//        self.videoSessionStartAnalytics()
    }
    
//    func videoSessionStartAnalytics() {
//        let isPreRollAds = self.vlPlayer?.isVideoHavingPreRollAds() ?? false
//        let currentPlaybackTime = self.vlPlayer?.getCurrentPlaybackTime() ?? 0.0
//        let endPlaybackTime = self.vlPlayer?.getChapterEndTime() ?? 0.0
//        
//        let chapterInfo = ChapterInfoModel(
//            havingPreRollAds: isPreRollAds,
//            startTime: currentPlaybackTime,
//            endTime: endPlaybackTime
//        )
//        
//        if let contentInfo = self.getVideoInfo() {
//            AnalyticsHelper.shared.triggerVideoSessionStartEvent(
//                    contentInfo: contentInfo,
//                    chapterInfo: chapterInfo
//                )
//        }
//    }

    // Called when video is paused
    func videoPause(timestamp: Double, playerTag: String) {
        videoPlayerControlsView?.setPlayButtonState(state: false)
        videoPlayerCustomView?.viewModel?.updatePlayingState(isPlaying: false)
        
//        AnalyticsHelper.shared.playerDidPaused()

    }

    // Called when video resumes from pause
    func videoResume(timestamp: Double, playerTag: String, metaDataInfo: [String : Any]?) {
        videoPlayerControlsView?.setPlayButtonState(state: true)
        videoPlayerCustomView?.viewModel?.updatePlayingState(isPlaying: true)
        
//        if VLAnalytics.shared.isMediaSessionTracked == false {
//            self.videoSessionStartAnalytics()
//        } else {
//            AnalyticsHelper.shared.playerDidStartPlaying()
//        }
    }

    // Called when video finishes playback
    func videoFinished(playerTag: String) {
        let currentTime = vlPlayer?.getCurrentVideoDuration() ?? 0.0
        self.updateWatchHistoryDisplay(watchedTime: currentTime, watchedPercentage: 100)
        videoPlayerControlsView?.setPlayButtonState(state: false)
        videoPlayerCustomView?.viewModel?.updatePlayingState(isPlaying: false)

//        AnalyticsHelper.shared.trackVideoCompletedAnalytics()
    }

    // Handles playback errors and shows alert if needed
    func videoPlaybackError(currentTime: Double, errorMessage: String, errorCode: String, playerTag: String) {
        videoPlayerControlsView?.setPlayButtonState(state: false)
        videoPlayerCustomView?.viewModel?.updatePlayingState(isPlaying: false)

        if !errorMessage.isEmpty {
            showAlert(message: errorMessage)

//            AnalyticsHelper.shared.trackVideoFailErrorAnalytics(errorMessage: errorMessage)
        }
    }

    // Handles errors during video fetch and updates UI accordingly
    func videoFetchError(error: VLError?, playerTag: String?, contentResponse: Dictionary<String, AnyObject>?) {
        let errorDescription = buildErrorDescription(from: error)

        print("Error VL:", errorDescription)
        print("VideoFetchError: contentResponse:", contentResponse as Any)

        DispatchQueue.main.async { [weak self] in
            self?.timerLabel.isHidden = true
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

        if isChapteringCuePointEnable {
            refreshLiveMoments()
        }

        self.invalidatePlayerTempPassIfOutOfWindow()
    }
    
    func videoPlayerProgressOnDefinedInterval(currentTime: Double, totalTime: Double, playerTag: String) {
        self.updateWatchHistoryDisplay(watchedTime: currentTime, watchedPercentage: (currentTime/totalTime)*100)
    }

    // Calculates elapsed time, considering start-over if available
    private func calculateElapsedTime(currentTime: Double, totalTime: Double) -> Double {
        guard let _ = vlPlayer?.getStartOverTime() else { return currentTime }
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
    
    func playerDidChangeClosedCaptionLanguage(language: String?) {
        DispatchQueue.main.async { [weak self] in
            let ccEnabled = UserDefaults.standard.bool(forKey: "CLOSED CAPTION AVAILABLE")
            self?.videoPlayerCustomView?.viewModel?.updateSubtitleState(isEnabled: ccEnabled)
        }
    }
    
    func adStarted(currentTime: Double, adTag: String?, playerTag: String, player: AVPlayer, metaDataInfo: [String : Any]?) {
        debugPrint("adStarted")
    }

    /// Receives computed chapter cue positions from the SDK every second.
    /// Forwards them to the custom skin's view model when using `.custom` controls,
    /// so chapter markers and the drag-preview bubble (including `showChapterTitleTillCuePoint`
    /// behaviour) appear on the custom seekbar just as they do on the `.customTheme` built-in skin.
    func chapterCuePointsUpdated(cuePoints: [NSNumber], duration: Double, playerTag: String) {
        guard isChapterButtonAction, let viewModel = videoPlayerCustomView?.viewModel else { return }

        // Pair every cue position with its OWN label/origLength using the SDK's in-window
        // mapping, which resolves each surviving cue point together with its window position.
        //
        // The previous approach aligned labels to cue points purely by array index — taking a
        // `prefix` of the earliest N segments (sorted by startTime). That only holds while the
        // in-window set happens to be the first N segments. As soon as the DVR/live window drops
        // the earliest cues (e.g. after entering a stream-start time in the chaptering popup, or
        // as the live edge advances) the remaining in-window cues are no longer the first N, so
        // each drag title shifted onto the wrong cue point. The mismatch only affected the
        // `.custom` skin, which re-derives the drag title here; the built-in `.customTheme` skin
        // resolves titles inside the SDK and therefore stayed correct.
        let sortedPositions = cuePoints.map { $0.doubleValue }.sorted()
        let sortedMappings = (vlPlayer?.chapteringCuePointsInCurrentWindow() ?? [])
            .sorted { $0.windowPosition < $1.windowPosition }

        let resolvedLabels: [String]
        let resolvedOrigLengths: [Double]
        if sortedMappings.count == sortedPositions.count {
            resolvedLabels = sortedMappings.map { $0.cuePoint.label }
            resolvedOrigLengths = sortedMappings.map { $0.cuePoint.origLength ?? 0 }
        } else {
            // No reliable 1:1 pairing available this tick — draw the markers without drag
            // titles rather than risk labelling them with the wrong chapter.
            resolvedLabels = []
            resolvedOrigLengths = []
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            viewModel.setChapterCuePoints(
                cuePoints: sortedPositions,
                duration: duration,
                labels: resolvedLabels,
                origLengths: resolvedOrigLengths,
                cueConfig: self.chapterCueConfig
            )
        }
    }

}
