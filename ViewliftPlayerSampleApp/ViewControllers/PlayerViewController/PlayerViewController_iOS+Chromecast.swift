//
//  PlayerViewController_iOS+Chromecast.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
import Foundation

extension PlayerViewController_iOS {
    
    /// Called when the Chromecast connection status changes
    /// - Parameter isConnected: Indicates whether Chromecast is connected
    func chromeCastConnectionStatusUpdate(isConnected: Bool) {
        print("Cast connected:", isConnected)
    }
    
    /// Gets the current Chromecast connection status from the player
    func getChromeCastConnectedStatus() {
        print("Cast connected:", vlPlayer.getChromeCastConnectedStatus())
    }
    
    /// Called when a seek operation starts on Chromecast
    /// - Parameter time: The time (in seconds) where the seek started
    func seekStarted(time: TimeInterval) {
        print("Seek Started: \(time)")
    }
    
    /// Called when a seek operation completes on Chromecast
    /// - Parameter time: The time (in seconds) where the seek completed
    func seekCompleted(time: TimeInterval) {
        print("Seek Completed: \(time)")
    }
}
