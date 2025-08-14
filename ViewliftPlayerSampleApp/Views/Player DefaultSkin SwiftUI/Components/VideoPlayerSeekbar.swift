//
//  VideoPlayerSeekbar.swift
//  VLPlayer
//
//  Created by Japneet Singh on 03/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import SwiftUI

struct VideoPlayerSeekbar: View {
    @ObservedObject var viewModel: PlayerControlsViewModel
    @GestureState private var isDragging = false
    @State private var lastDragValue: CGFloat = 0
    
    private var isLandscape: Bool {
        viewModel.isLandscape
    }
    
    private var iconScale: CGFloat {
        UIDevice.isIPad ? 1.5 : 1.0
    }
    
    var body: some View {
        VStack {
            if viewModel.playerControlsType == .liveControls {
                liveControls
            } else {
                videoSeekbar
            }
        }
    }
    
    var liveControls: some View {
        HStack {
            Spacer()
            Button(action: viewModel.seekToLiveTapped) {
                Text(viewModel.getLiveLabel)
                    .font(.system(size: 12 * iconScale))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10 * iconScale)
                    .padding(.vertical, 6 * iconScale)
                    .background(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.red)
                    )
            }
        }
    }
    
    var videoSeekbar: some View {
        HStack(alignment: .center, spacing: 4 * iconScale) {
            GeometryReader { geometry in
                let trackWidth = geometry.size.width
                let thumbSize: CGFloat = 20 * iconScale
                let trackHeight: CGFloat = 4 * iconScale
                
                // Calculate progress (0.0 to 1.0)
                let progress = viewModel.playerState.currentTime / 100.0
                let thumbPosition = min(CGFloat(progress) * (trackWidth - thumbSize), trackWidth)
                let activeWidth = thumbPosition + (thumbSize / 2)
                
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(viewModel.getProgressBarBGColor().opacity(0.4))
                        .frame(height: trackHeight)
                    
                    // Progress track (active portion)
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(viewModel.getProgressBarColor())
                        .frame(width: max(0, activeWidth), height: trackHeight)
                    
                    if !viewModel.adsCuePoints.isEmpty,
                       viewModel.adsDuration > 0 {
                        // Cue points overlaid on top of track
                        let factor = trackWidth / viewModel.adsDuration
                        ForEach(viewModel.adsCuePoints, id: \.self) { cueTime in
                            if viewModel.adsDuration > 0 {
                                let cuePosition = CGFloat(cueTime) * CGFloat(factor)
                                Rectangle()
                                    .fill(viewModel.getCueIconColor())
                                    .frame(width: 2, height: trackHeight)
                                    .offset(x: cuePosition)
                            }
                        }
                    }
                    
                    // Draggable thumb
                    Circle()
                        .fill(viewModel.getIconColor())
                        .frame(width: thumbSize, height: thumbSize)
                        .scaleEffect(isDragging ? 1.3 : 1.0)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .offset(x: thumbPosition)
                        .gesture(
                            // Combine the seek gesture with tap detection
                            seekGesture(trackWidth: trackWidth, thumbSize: thumbSize)
                        )
                        .animation(.easeOut(duration: 0.15), value: isDragging)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: SeekbarThumbOriginPreferenceKey.self,
                            value: ["seekbar" : geo.frame(in: .named("playerContainer"))]
                        )
                    }
                )
                .frame(height: thumbSize, alignment: .center)
                .contentShape(Rectangle())
            }
            .frame(height: 26 * iconScale, alignment: .center,)
            
            HStack(alignment: .center, spacing: 4 * iconScale) {
                // Time label
                Text(viewModel.getTimeLabel)
                    .font(.system(size: (isLandscape ? 14 : 12) * iconScale, weight: .medium))
                    .foregroundColor(.white)
                
                //Live Button
                if viewModel.playerControlsType == .dvrControls {
                    Button(action: viewModel.seekToLiveTapped) {
                        Text(viewModel.getLiveLabel)
                            .font(.system(size: 12 * iconScale))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10 * iconScale)
                            .padding(.vertical, 6 * iconScale)
                            .background(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.red)
                            )
                    }
                }
            }
            .padding(.bottom, 6 * iconScale)
        }
        .frame(alignment: .center)
        .animation(.easeInOut, value: viewModel.playerState.currentTime)
    }
    
    private func seekGesture(trackWidth: CGFloat, thumbSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { gesture in
                if !isDragging {
                    // Store initial position when drag starts
                    let currentProgress = viewModel.playerState.currentTime / 100.0
                    lastDragValue = CGFloat(currentProgress) * (trackWidth - thumbSize)
                }
                
                // Calculate new position based on translation from start point
                let newPosition = lastDragValue + gesture.location.x
                let clampedPosition = max(0, min(newPosition, trackWidth - thumbSize))
                
                // Calculate time value (0-100)
                let progress = clampedPosition / (trackWidth - thumbSize)
                let newTime = min(100, max(0, Double(progress * 100)))
                
                // Update the view model
                viewModel.playerState.currentTime = newTime
                viewModel.sliderTracking(time: newTime)
            }
            .onEnded { gesture in
                // Calculate final position
                let finalPosition = lastDragValue + gesture.location.x
                let clampedPosition = max(0, min(finalPosition, trackWidth - thumbSize))
                
                // Calculate final time value
                let progress = clampedPosition / (trackWidth - thumbSize)
                let finalTime = min(100, max(0, Double(progress * 100)))
                
                // Commit the final value
                viewModel.playerState.currentTime = finalTime
                viewModel.sliderEndedTracking(time: finalTime)
                
                // Reset for next drag
                lastDragValue = 0
            }
    }
}

struct SeekbarThumbOriginPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
