//
//  PlayerViewController_TempPass.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 16/09/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import Foundation
#if os(iOS)
import VLAuthenticationFramework
#else
import VLAuthenticationFramework_tvOS
#endif

extension PlayerViewController_tvOS {
    func getTempPassPayload() async {
        guard AppDelegate.shared.adobePlayerTempPass[self.channelkey] == nil else { return }

        do {
            let response = try await VLAuthentication.sharedInstance.getAdobeTempPass(
                channelIds: self.channelId
            )

            switch response {
            case .success(let payloadOptional):
                if let payload = payloadOptional {
                    AppDelegate.shared.adobePlayerTempPass[self.channelkey] = payload
                }
            case .failure(_):
                self.vlPlayer?.destroy()
                break
            }
        } catch {
            self.vlPlayer?.destroy()
        }
    }
    
    func cleanupAndReloadPlayerView(){
        Task { [weak self] in
            guard let self = self else { return }
            self.vlPlayer?.destroy()
            await self.loadPlayerView()
        }
    }
    
    
    
    func invalidatePlayerTempPassIfOutOfWindow() {
        guard let tempPass = AppDelegate.shared.adobePlayerTempPass[self.channelkey] else {
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
            
            AppDelegate.shared.adobePlayerTempPass[self.channelkey] = nil
            
            self.cleanupAndReloadPlayerView()
            
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
