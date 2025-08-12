//
//  PlayerViewController_iOS+PIP.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib

extension PlayerViewController_iOS {
    
    /// Called when the PiP setup is completed
    /// - Parameter isPIPSelected: Indicates if PiP was selected by the user
    func pictureInPictureSetupCompleted(isPIPSelected: Bool) {
        print(#function)
    }
    
    /// Called just before PiP is about to start
    func pictureInPictureWillStart() {
        print(#function)
    }
    
    /// Called when PiP has started
    /// Disables the requirement for linear playback in PiP mode
    func pictureInPictureDidStart() {
        vlPlayer.requireLinearPlaybackInPictureInPicture(isRequired: false)
    }
    
    /// Called when the user requests to restore the full player from PiP
    func pictureInPictureRestoreFullPlayer() {
        print(#function)
    }
    
    /// Called just before PiP is about to stop
    func pictureInPictureWillStop() {
        print(#function)
    }
    
    /// Called after PiP has stopped
    func pictureInPictureDidStop() {
        print(#function)
    }
    
    /// Called if PiP fails to start
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - playerTag: Identifier for the player instance
    func pictureInPictureDidFailedToStart(error: VLError, playerTag: String) {
        print(#function)
    }
}
