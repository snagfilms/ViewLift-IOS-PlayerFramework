//
//  PlayerViewController+PlayerControlsDelegate.swift
//  ViewliftPlayerSampleApp
//
//  Created by Japneet Singh on 14/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
import UIKit
import SwiftUI
import AVFAudio

//Delegate methods
extension PlayerViewController_iOS: PlayerControlsViewDelegate {
    
    func playPauseTapped(isPlaying: Bool) {
        vlPlayer.playPauseTapped(isPlaying: isPlaying)
    }
    
    func muteTapped(isMuted: Bool) {
        vlPlayer?.shouldPlayMuted(isMuted: isMuted)
    }
    
    func slowMotionTapped(isSlowMotion: Bool) {
        vlPlayer.setPlaybackRate(playbackSpeed: isSlowMotion ? 0.3 : 1)
    }
    
    func controlsLockTapped(isLocked: Bool) {
        debugPrint("controlsLockTapped: \(isLocked)")
    }
    
    func subtitleTapped(isEnabled: Bool) {
        vlPlayer.subtitleTapped(isEnabled: isEnabled)
    }
    
    func piPTapped() {
        self.vlPlayer.pictureInPictureClicked(isPipSelected: true)
    }
    
    func castingTapped(button: UIButton) {
        self.vlPlayer.castButtonTapped(sender: button)
        self.vlPlayer.play()
    }
    
    func airPlayTapped() {
        debugPrint("airPlayTapped")
    }
    
    func fullScreenTapped(isFullScreen: Bool) {
        vlPlayer.goFullScreen(isFullScreen)
    }
    
    func rewindTapped() {
        vlPlayer.rewindTapped()
    }
    
    func forwardTapped() {
        vlPlayer.forwardTapped()
    }
    
    func settingsTapped() {
        vlPlayer.defaultSettingsTapped()
    }
    
    func seekToLive() {
        vlPlayer?.seekToLivePosition()
    }
    
    func sliderBeginTracking(time: TimeInterval) {
        vlPlayer.sliderBeginTracking(time: time)
    }
    
    func sliderChangedTracking(time: TimeInterval) {
        vlPlayer.sliderChangedTracking(time: time)
    }
    
    func sliderEndedTracking(time: TimeInterval) {
        vlPlayer.sliderEndedTracking(time: time)
    }
    
    func setupPictureInPicture() {
        vlPlayer.setupPictureInPicture()
    }
    
    func volumeChange(sliderValue: Float) {
        vlPlayer.setVolumeLevel(volumeLevel: Int(sliderValue * 100))
    }
}
