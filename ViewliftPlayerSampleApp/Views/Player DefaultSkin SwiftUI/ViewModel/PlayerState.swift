//
//  PlayerState.swift
//  playerKinUI
//
//  Created by Japneet Singh on 02/08/25.
//


import SwiftUI

// MARK: - Player State Model
struct PlayerState {
    var isPlaying: Bool = true
    var currentTime: TimeInterval = 0
    var totalTime: TimeInterval = 100
    var liveLabel: String = "LIVE"
    var timeLabel: String = "00:00/ 00:00"
    var volume: Float = 1.0
    var isMuted: Bool = false
    var isSlowMotion: Bool = false
    var isControlsLocked: Bool = false
    var subtitle: Bool = false
    var isPiP: Bool = false
    var isCasting: Bool = false
    var title: String = ""
}
