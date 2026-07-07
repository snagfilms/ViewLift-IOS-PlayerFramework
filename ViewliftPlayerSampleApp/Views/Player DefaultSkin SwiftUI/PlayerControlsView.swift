//
//  PlayerControlsView.swift
//  playerKinUI
//
//  Created by Japneet Singh on 02/08/25.
//

import SwiftUI

// MARK: - Player Controls View
struct PlayerControlsView: View {
    @ObservedObject private var viewModel: PlayerControlsViewModel
    
    init(viewModel: PlayerControlsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            // Video Content Background
            Color.black.opacity(0.75)
                .ignoresSafeArea()
            
            // Player Controls Overlay
            PlayerControlsOverlay(
                viewModel: viewModel
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(name: "playerContainer")
        .onPreferenceChange(SeekbarThumbOriginPreferenceKey.self) { values in
            viewModel.handleFramesUpdate(values)
        }
    }
}

// MARK: - Player Controls Overlay
struct PlayerControlsOverlay: View {
    @ObservedObject var viewModel: PlayerControlsViewModel
    
    @State private var isAirPlayActive = false
    @State private var shouldPresentAirPlay = false
    
    private var isLandscape: Bool {
        viewModel.isLandscape
    }
    
    private var iconScale: CGFloat {
        UIDevice.isIPad ? 1.3 : 1.0
    }
    
    var body: some View {
        ZStack {
            if isLandscape && viewModel.playerState.isControlsLocked {
                landscapeLockedControls
                
            } else {
                VStack(spacing: 0) {
                    Spacer()
                    centerPlayButton
                    Spacer()
                }

                VStack(spacing: 0) {
                    // Top Controls
                    topControls
                    
                    Spacer()
                    
                    // Bottom Controls
                    bottomControls
                }
                .padding(.horizontal, isLandscape ? 15 : 15)
                .padding(.vertical, isLandscape ? 20 : 15)
                // Keep the top/bottom controls (which host the seekbar and its chapter
                // drag-preview bubble) above the center play controls, so the bubble stays
                // in front when it overlaps them in the compact player. The center controls
                // remain tappable through the transparent spacer in the middle of this layer.
                .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: SeekbarThumbOriginPreferenceKey.self,
                    value: ["player" : geo.frame(in: .named("playerContainer"))]
                )
            }
        )
    }
    
    private var topControls: some View {
        HStack {
            if isLandscape {
                HStack(spacing: 16) {
                    // Close Button (Landscape)
                    Button(action: {
                        viewModel.toggleFullScreen(isFullScreen: false)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18 * iconScale))
                            .foregroundColor(viewModel.getIconColor())
                    }
                    
                    // Marquee Text (Landscape)
                    MarqueeText(
                        text: viewModel.getTitle,
                        font: UIFont.systemFont(ofSize: 16 * iconScale, weight: .semibold),
                        leftFade: 16,
                        rightFade: 16,
                        startDelay: 1
                    )
                    .foregroundColor(viewModel.getTextColor())
                    .frame(maxWidth: .infinity)
                }
            }
            
            Spacer()
            
            if isLandscape {
                // Landscape-specific top controls
                HStack(spacing: 30 * iconScale) {
                    
                    if viewModel.playerControlsConfig.isPIPSupported {
                        // Pip Button
                        Button(action: viewModel.togglePiP) {
                            Image(systemName: "pip.enter")
                                .font(.system(size: 18 * iconScale))
                                .foregroundColor(viewModel.getIconColor())
                        }
                    }
                    
                    if viewModel.playerControlsConfig.isChromeCastSupported {
                        // Casting Button
                        CastUIButton(
                            frame: CGRect(x: 0, y: 0, width: 20 * iconScale, height: 20 * iconScale)
                        ) { button in
                            viewModel.castButtonTapped(sender: button)
                        }
                        .frame(width: 20 * iconScale, height: 20 * iconScale)
                    }
                    
                    if viewModel.playerControlsConfig.isAirPlaySupported {
                        // Airplay Button
                        Button(action: {
                            shouldPresentAirPlay = true
                        }) {
                            if let airPlayImage = UIImage(
                                named: "airplay_news",
                                in: Bundle(identifier: "com.viewlift.vlplayer"),
                                compatibleWith: nil
                            ) {
                                Image(uiImage: airPlayImage.withRenderingMode(.alwaysTemplate))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20 * iconScale, height: 20 * iconScale)
                                    .foregroundColor(viewModel.getIconColor())
                            } else {
                                Image(systemName: isAirPlayActive ? "airplay.audio.circle.fill" : "airplay.audio.circle")
                                    .font(.system(size: 20 * iconScale))
                                    .foregroundColor(viewModel.getIconColor())
                            }
                        }
                        .background(
                            // Hidden AirPlay view for programmatic triggering
                            CustomAirPlayButton(
                                shouldPresent: $shouldPresentAirPlay,
                                isAirPlayActive: $isAirPlayActive
                            ) { isActive in
                                handleAirPlayStatusChange(isActive)
                            }
                                .frame(width: 0, height: 0)
                                .hidden()
                        )
                        .padding(.trailing, 10)
                    }
                    
                }
                
            } else {
                // Portrait-specific top controls
                HStack(spacing: 25) {
                    
                    if viewModel.playerControlsConfig.isChromeCastSupported {
                        // Casting Button
                        CastUIButton(
                            frame: CGRect(x: 0, y: 0, width: 20 * iconScale, height: 20 * iconScale)
                        ) { button in
                            viewModel.castButtonTapped(sender: button)
                        }
                        .frame(width: 20 * iconScale, height: 20 * iconScale)
                    }
                    
                    if viewModel.playerControlsConfig.isAirPlaySupported {
                        // Airplay Button
                        Button(action: {
                            shouldPresentAirPlay = true
                        }) {
                            if let airPlayImage = UIImage(
                                named: "airplay_news",
                                in: Bundle(identifier: "com.viewlift.vlplayer"),
                                compatibleWith: nil
                            ) {
                                Image(uiImage: airPlayImage.withRenderingMode(.alwaysTemplate))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20 * iconScale, height: 20 * iconScale)
                                    .foregroundColor(viewModel.getIconColor())
                            } else {
                                Image(systemName: isAirPlayActive ? "airplay.audio.circle.fill" : "airplay.audio.circle")
                                    .font(.system(size: 20 * iconScale))
                                    .foregroundColor(viewModel.getIconColor())
                            }
                        }
                        .background(
                            // Hidden AirPlay view for programmatic triggering
                            CustomAirPlayButton(
                                shouldPresent: $shouldPresentAirPlay,
                                isAirPlayActive: $isAirPlayActive
                            ) { isActive in
                                handleAirPlayStatusChange(isActive)
                            }
                                .frame(width: 0, height: 0)
                                .hidden()
                        )
                    }
                    
                    // Fullscreen Button
                    Button(action: {
                        viewModel.toggleFullScreen(isFullScreen: true)
                    }) {
                        Image(systemName: "arrow.down.left.and.arrow.up.right")//arrow.up.left.and.arrow.down.right"
                            .font(.system(size: 18 * iconScale))
                            .foregroundColor(viewModel.getIconColor())
                    }
                }
            }
        }
    }
    
    private func handleAirPlayStatusChange(_ isActive: Bool) {
        isAirPlayActive = isActive
        viewModel.seekToLiveTapped()
    }
    
    private var centerPlayButton: some View {
        
        GeometryReader { geometry in
            HStack(spacing: 30) {
                
                if viewModel.playerControlsType != .liveControls {
                    //Rewind Button
                    Button(action: viewModel.rewindTapped) {
                        Image(systemName: "10.arrow.trianglehead.counterclockwise")
                            .font(.system(size: (isLandscape ? 36 : 28) * iconScale))
                            .foregroundColor(viewModel.getIconColor())
                    }
                }
                
                //play-pause Button
                Button(action: viewModel.togglePlayPause) {
                    Image(systemName: viewModel.playerState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: (isLandscape ? 36 : 30) * iconScale))
                        .foregroundColor(viewModel.getIconColor())
                }
                
                if viewModel.playerControlsType != .liveControls {
                    //Forward Button
                    Button(action: viewModel.forwardTapped) {
                        Image(systemName: "10.arrow.trianglehead.clockwise")
                            .font(.system(size: (isLandscape ? 36 : 28) * iconScale))
                            .foregroundColor(viewModel.getIconColor())
                    }
                }
            }
            //.padding(.trailing, isLandscape ? geometry.safeAreaInsets.leading : 0)
            .padding(.trailing, viewModel.isLandscape ? UIApplication.shared.windows.first?.safeAreaInsets.left ?? 0 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 2) {
            // Progress Bar
            progressBar
            
            // Control Buttons Row
            controlButtonsRow
        }
    }
    
    private var progressBar: some View {
        VStack(spacing: 0) {
            VideoPlayerSeekbar(viewModel: viewModel)
                .frame(maxWidth: .infinity)
        }
    }
    
    private var controlButtonsRow: some View {
        HStack {
            if isLandscape {
                landscapeControls
            } else {
                portraitControls
            }
        }
    }
    
    private var landscapeControls: some View {
        HStack(spacing: 15) {
            
            // Volume/Mute Button
            Button(action: viewModel.toggleMute) {
                Image(systemName: viewModel.playerState.isMuted ? "speaker.slash.fill" : "speaker.2.fill")
                    .font(.system(size: 18 * iconScale))
                    .foregroundColor(viewModel.getIconColor())
                    .frame(width: 20 * iconScale)
                
                Text(viewModel.playerState.isMuted ? "Volume Off" : "Volume On")
                    .font(.system(size: 12 * iconScale))
                    .foregroundColor(viewModel.getTextColor())
            }
            
            if viewModel.playerControlsConfig.isSlowMoSupported {
                // Slow Motion Button
                Button(action: viewModel.toggleSlowMotion) {
                    Text("Slow mo")
                        .font(.system(size: 12 * iconScale))
                        .foregroundColor(viewModel.getTextColor())
                        .padding(.horizontal, 10 * iconScale)
                        .padding(.vertical, 6 * iconScale)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(viewModel.playerState.isSlowMotion ? Color.gray.opacity(0.8) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.gray.opacity(0.8), lineWidth: 1)
                        )
                }
            }
            
            // Lock Controls Button
            Button(action: viewModel.toggleControlsLock) {
                Image(systemName: viewModel.playerState.isControlsLocked ? "lock.open" : "lock.fill")
                    .font(.system(size: 18 * iconScale))
                    .foregroundColor(viewModel.getIconColor())
                
                Text(viewModel.playerState.isControlsLocked ? "UnLock Controls?" : "Lock Controls")
                    .font(.system(size: 12 * iconScale))
                    .foregroundColor(viewModel.getTextColor())
            }
            
            if viewModel.playerControlsConfig.isSubTitleSupported {
                // Subtitle Button
                Button(action: viewModel.toggleSubtitle) {
                    Image(systemName: viewModel.playerState.subtitle ? "captions.bubble.fill" : "captions.bubble")
                        .font(.system(size: 18 * iconScale))
                        .foregroundColor(viewModel.getIconColor())
                    
                    Text("Subtitles: " + (viewModel.playerState.subtitle ? "On" : "Off"))
                        .font(.system(size: 12 * iconScale))
                        .foregroundColor(viewModel.getTextColor())
                }
            }
            
            if viewModel.playerControlsConfig.isSettingsSupported {
                // Settings Button
                Button(action: viewModel.settingsTapped) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18 * iconScale))
                        .foregroundColor(viewModel.getIconColor())
                    
                    Text("Settings")
                        .font(.system(size: 12 * iconScale))
                        .foregroundColor(viewModel.getTextColor())
                }
            }
            
            Spacer()
        }
    }
    
    private var landscapeLockedControls: some View {
        VStack() {
            Spacer()
            
            // Lock Controls Button
            Button(action: viewModel.toggleControlsLock) {
                Image(systemName: viewModel.playerState.isControlsLocked ? "lock.open" : "lock.fill")
                    .font(.system(size: 20 * iconScale))
                    .foregroundColor(viewModel.getIconColor())
                
                Text(viewModel.playerState.isControlsLocked ? "UnLock Controls?" : "Lock Controls")
                    .font(.system(size: 12 * iconScale))
                    .foregroundColor(viewModel.getTextColor())
            }
            .padding(.bottom, 18 * iconScale)
        }
        .padding(.trailing, viewModel.isLandscape ? UIApplication.shared.windows.first?.safeAreaInsets.left ?? 0 : 0)
    }
    
    private var portraitControls: some View {
        HStack(spacing: 20) {
            
            // Volume Button
            Button(action: viewModel.toggleMute) {
                Image(systemName: viewModel.playerState.isMuted ? "speaker.slash.fill" : "speaker.2.fill")
                    .font(.system(size: 18 * iconScale))
                    .foregroundColor(viewModel.getIconColor())
            }
            .frame(width: 18 * iconScale)
            
            if viewModel.playerControlsConfig.isSlowMoSupported {
                // Slow Motion Button
                Button(action: viewModel.toggleSlowMotion) {
                    Text("Slow mo")
                        .font(.system(size: 12 * iconScale))
                        .foregroundColor(viewModel.getTextColor())
                        .padding(.horizontal, 10 * iconScale)
                        .padding(.vertical, 6 * iconScale)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(viewModel.playerState.isSlowMotion ? Color.gray.opacity(0.8) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.gray.opacity(0.8), lineWidth: 1)
                        )
                }
            }
            
            Spacer()
            
            if viewModel.playerControlsConfig.isPIPSupported {
                // PiP Button (Portrait)
                Button(action: viewModel.togglePiP) {
                    Image(systemName: "pip.enter")
                        .font(.system(size: 18 * iconScale))
                        .foregroundColor(viewModel.getIconColor())
                }
            }
        }
    }
}
