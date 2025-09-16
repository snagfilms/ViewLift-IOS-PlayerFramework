//
//  PlayerViewController_TempPass.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 16/09/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import Foundation
import VLAuthentication

extension PlayerViewController_tvOS {
    func getTempPassPayload(channelIds: [String] = []) async {
        guard AppDelegate.shared.adobePlayerTempPass == nil else { return }

        do {
            let response = try await VLAuthentication.sharedInstance.getAdobeTempPass(channelIds: channelIds)

            switch response {
            case .success(let payloadOptional):
                if let payload = payloadOptional {
                    AppDelegate.shared.adobePlayerTempPass = payload
                }
            case .failure(_):
//                self.cleanupAndReloadPlayerView()
                break
            }
        } catch {
//            self.cleanupAndReloadPlayerView()
        }
    }
    
    func invalidatePlayerTempPassIfOutOfWindow() {
        guard
            let tempPass = AppDelegate.shared.adobePlayerTempPass else {
            timerLabel.text = "00:00"
            timerLabel.isHidden = true
            return
        }

        let na = tempPass.notAfter
        
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let end = Int64(na)

        let remainingMs = end - nowMs
        if remainingMs <= 0 {
            timerLabel.text = "00:00"
            timerLabel.isHidden = true
            
            AppDelegate.shared.adobePlayerTempPass = nil
            
//            self.cleanupAndReloadPlayerView()
            
            DispatchQueue.main.async { [weak self] in
                self?.customPaywallView?.update("The temporary access duration limit has been exceeded.")
            }
            return
        }

        // Convert milliseconds to seconds
        let remainingSeconds = remainingMs / 1000

        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60

        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        timerLabel.isHidden = false
    }
}
