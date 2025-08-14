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

//Ad manager
extension PlayerViewController_iOS: AdManagerDelegate {
    
    func setCuePointsFromPlayer(adModel: SSAIAdsModel?, duration: TimeInterval) {
        videoPlayerCustomView?.viewModel?.setCuePointsFromPlayer(adModel: adModel, duration: duration)
    }
}

//Delegate methods
extension PlayerViewController_iOS: PlayerControlsViewDelegate {
    
    func playPauseTapped(isPlaying: Bool) {
        vlPlayer.playPauseTapped(isPlaying: isPlaying)
    }
    
    func muteTapped(isMuted: Bool) {
        vlPlayer.muteTapped(isMuted: isMuted)
    }
    
    func slowMotionTapped(isSlowMotion: Bool) {
        vlPlayer.slowMotionTapped(isSlowMotion: isSlowMotion)
    }
    
    func controlsLockTapped(isLocked: Bool) {
        vlPlayer.controlsLockTapped(isLocked: isLocked)
    }
    
    func subtitleTapped(isEnabled: Bool) {
        vlPlayer.subtitleTapped(isEnabled: isEnabled)
    }
    
    func piPTapped() {
        vlPlayer.piPTapped()
    }
    
    func castingTapped(button: UIButton) {
        vlPlayer.castingTapped(button: button)
    }
    
    func airPlayTapped() {
        vlPlayer.airPlayTapped()
    }
    
    func fullScreenTapped(isFullScreen: Bool) {
        vlPlayer.fullScreenTapped(isFullScreen: isFullScreen)
    }
    
    func rewindTapped() {
        vlPlayer.rewindTapped()
    }
    
    func forwardTapped() {
        vlPlayer.forwardTapped()
    }
    
    func settingsTapped() {
        vlPlayer.settingsTapped()
    }
    
    func seekToLive() {
        vlPlayer.seekToLive()
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
    
    func volumeChange(sliderValue: Int) {
        vlPlayer.volumeChange(sliderValue: sliderValue)
    }
}
