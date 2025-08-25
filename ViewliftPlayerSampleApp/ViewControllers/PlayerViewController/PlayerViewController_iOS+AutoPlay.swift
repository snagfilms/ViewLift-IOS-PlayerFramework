//
//  PlayerViewController_iOS+AutoPlay.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 25/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import Foundation


extension PlayerViewController_iOS {
    /// This is called when AutoPlay UI is shown
    func autoPlayUIInitiated() {
        // make changes to your AutoPlay ui
    }
    /// This is called when AutoPlay UI is dismissed. This is called for default UI
    func autoPlayUIDimissed(isPlayingNextContent: Bool) {
        if isPlayingNextContent{
            // nextcontent will play and ui dismissed
        }else{
            // ui dismissed
        }
    }
}
