//
//  PlayerViewController_iOS+Chromecast.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
import Foundation

extension PlayerViewController_iOS: ChromeCastPlaybackDelegate {
    
    /// Called when the Chromecast connection status changes
    /// - Parameter isConnected: Indicates whether Chromecast is connected
    func chromeCastConnectionStatusUpdate(isConnected: Bool) {
        debugPrint("Cast connected:", isConnected)
    }
    
    /// Called when ChromeCast starts connecting device
    func chromeCastStartedConnectingDevice() {
        debugPrint("Cast started connecting:")
    }
    
    /// Gets the current Chromecast connection status from the player
    private func getChromeCastConnectedStatus() {
        debugPrint("Cast connected:", vlPlayer.getChromeCastConnectedStatus())
    }
    
}
