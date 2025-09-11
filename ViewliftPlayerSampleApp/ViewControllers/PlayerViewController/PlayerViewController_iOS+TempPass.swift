//
//  PlayerViewController_iOS+TempPass.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 10/09/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import VLAuthentication
import Foundation
import VLPlayerLib
import UIKit

extension PlayerViewController_iOS {
    
    func getTempPassPayload(channelIds: [String] = []) async {
        guard AppDelegate.shared.playerTempPass == nil else { return }

        do {
            let response = try await VLAuthentication.sharedInstance.getAdobeTempPass(channelIds: channelIds)

            switch response {
            case .success(let payloadOptional):
                if let payload = payloadOptional {
                    AppDelegate.shared.playerTempPass = VLPlayer.PlayerAdobeTempPassPayload(
                        adbToken: payload.adbToken,
                        channelIds: payload.channelIds,
                        deviceIdentifier: payload.deviceIdentifier,
                        deviceInfo: payload.deviceInfo,
                        mvpdProvider: payload.mvpdProvider,
                        notAfter: payload.notAfter,
                        notBefore: payload.notBefore,
                        serializedToken: payload.serializedToken
                    )
                }
            case .failure(_):
                self.cleanupAndReloadPlayerView()
            }
        } catch {
            self.cleanupAndReloadPlayerView()
        }
    }
    
    func cleanupAndReloadPlayerView() {
        self.cleanupResources()
    }
 
    
    func invalidatePlayerTempPassIfOutOfWindow() {
        guard
            let tempPass = AppDelegate.shared.playerTempPass,
            let na = tempPass.notAfter
        else {
            timerLabel.text = "00:00"
            timerLabel.isHidden = true
            return
        }

        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let end = Int64(na)

        let remainingMs = end - nowMs
        if remainingMs <= 0 {
            timerLabel.text = "00:00"
            timerLabel.isHidden = true
            
            AppDelegate.shared.playerTempPass = nil
            
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

    func stopTempPassTimer() {
            self.tempPassTimer?.invalidate()
            self.tempPassTimer = nil
    }
    
    func startTempPassTimer() {
        DispatchQueue.main.async {
            self.stopTempPassTimer()
            
            self.timerLabel.text = ""
            
            self.tempPassTimer = Timer.scheduledTimer(
                timeInterval: 1.0,
                target: self,
                selector: #selector(self.timerFired),
                userInfo: nil,
                repeats: true
            )
        }
    }
    
   
    @objc private func timerFired() {
        invalidatePlayerTempPassIfOutOfWindow()
    }
}

