//
//  VideoPlayerVM_AudioListener.swift
//  VLPlayer
//
//  Created by Japneet Singh on 04/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

extension PlayerControlsViewModel {
    
    func startVolumeMonitoring() {
        do {
            try audioSession.setActive(true)
        } catch {
            debugPrint("Failed to activate audio session: \(error.localizedDescription)")
        }
        
        // Check initial volume state
        if !initiallyMuted{
            initiallyMuted = false
            let initialVolume = audioSession.outputVolume
            DispatchQueue.main.async {
                self.systemVolumeDidChange(systemVolume: initialVolume)
            }
        }
        
        volumeObserver = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] (audioSession, change) in
            guard let self = self else { return }
            let newVolume = change.newValue ?? audioSession.outputVolume
            
            DispatchQueue.main.async {
                self.systemVolumeDidChange(systemVolume: newVolume)
            }
        }
    }
    
    func stopVolumeMonitoring() {
        volumeObserver?.invalidate()
        volumeObserver = nil
    }
    
    func systemVolumeDidChange(systemVolume: Float) {
        playerState.volume = systemVolume
        delegate?.volumeChange(sliderValue: systemVolume)
        debugPrint("systemVolumeDidChange: \(systemVolume)")
        
        if systemVolume == 0.0 {
            delegate?.muteTapped(isMuted: true)
            playerState.isMuted = true
        } else {
            delegate?.muteTapped(isMuted: false)
            playerState.isMuted = false
        }
    }
}
