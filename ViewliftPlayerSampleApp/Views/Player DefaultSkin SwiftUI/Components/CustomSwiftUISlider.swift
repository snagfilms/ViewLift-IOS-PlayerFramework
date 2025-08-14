//
//  CustomSwiftUISlider.swift
//  playerKinUI
//
//  Created by Japneet Singh on 02/08/25.
//

import SwiftUI
//
//struct CustomSlider: View {
//    
//    @ObservedObject var viewModel: PlayerControlsViewModel
//    @Binding var value: Double
//    var orientation: UIDeviceOrientation
//    let range: ClosedRange<Double>
//    
//    private var isLandscape: Bool {
//        orientation.isLandscape
//    }
//    
//    var body: some View {
//        VStack {
//            if viewModel.playerControlsType == .liveControls {
//                liveControls
//                
//            } else {
//                nonLiveControls
//            }
//        }
//        .frame(height: 24)
//    }
//    
//    var liveControls: some View {
//        HStack {
//            Spacer()
//            // LIVE Button
//            Button(action: {}) {
//                Text("LIVE")
//                    .font(.system(size: 12 * iconScale))
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 10 * iconScale)
//                    .padding(.vertical, 6 * iconScale)
//                    .background(
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(Color.red)
//                    )
//            }
//        }
//    }
//    
//    var nonLiveControls: some View {
//        HStack(spacing: 10) {
//            GeometryReader { geometry in
//                let width = geometry.size.width
//                let thumbSize: CGFloat = 18 * iconScale
//                let trackHeight: CGFloat = 2.5 * iconScale
//                
//                let progress = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
//                let xOffset = max(0, progress * width)  * iconScale
//                
//                ZStack(alignment: .leading) {
//                    // Inactive track
//                    Capsule()
//                        .fill(Color.gray.opacity(0.8))
//                        .frame(height: trackHeight)
//                    
//                    // Active (red) track
//                    Capsule()
//                        .fill(Color.red)
//                        .frame(width: xOffset, height: trackHeight)
//                    
//                    // Thumb
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: thumbSize, height: thumbSize)
//                        .offset(x: xOffset - thumbSize / 2)
//                        .gesture(
//                            DragGesture(minimumDistance: 0)
//                                .onChanged { gesture in
//                                    let location = gesture.location.x
//                                    let percentage = min(max(0, location / width), 1)
//                                    value = range.lowerBound + Double(percentage) * (range.upperBound - range.lowerBound)
//                                }
//                        )
//                }
//            }
//            
//            Text(timeString(from: viewModel.playerState.currentTime) + "/ " + timeString(from: viewModel.playerState.totalTime))
//                .font(.system(size: (isLandscape ? 14 : 12) * iconScale))
//                .foregroundColor(.white)
//        }
//        .animation(.easeInOut, value: viewModel.playerState.currentTime)
//    }
//    
//    private var iconScale: CGFloat {
//        UIDevice.isIPad ? 1.5 : 1.0
//    }
//    
//    private func timeString(from timeInterval: TimeInterval) -> String {
//        let totalSeconds = Int(timeInterval)
//        let minutes = totalSeconds / 60
//        let seconds = totalSeconds % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
//    
//}


//struct CustomSwiftUISlider: View {
//    @ObservedObject var viewModel: PlayerControlsViewModel
//    let range: ClosedRange<Double>
//    @GestureState private var isDragging = false
//    
//    private var isLandscape: Bool {
//        viewModel.isLandscape
//    }
//    
//    private var iconScale: CGFloat {
//        UIDevice.isIPad ? 1.5 : 1.0
//    }
//    
//    var body: some View {
//        VStack {
//            if viewModel.playerControlsType == .liveControls {
//                liveControls
//            } else {
//                nonLiveControls
//            }
//        }
//        .frame(height: 24)
//    }
//    
//    var liveControls: some View {
//        HStack {
//            Spacer()
//            Button(action: viewModel.seekToLiveTapped) {
//                Text("LIVE")
//                    .font(.system(size: 12 * iconScale))
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 10 * iconScale)
//                    .padding(.vertical, 6 * iconScale)
//                    .background(
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(Color.red)
//                    )
//            }
//        }
//    }
//    
//    var nonLiveControls: some View {
//        HStack(spacing: 19 * iconScale) {
//            GeometryReader { geometry in
//                let width = geometry.size.width
//                let thumbSize: CGFloat = 18 * iconScale
//                let trackHeight: CGFloat = 2.5 * iconScale
//                
//                let duration = range.upperBound - range.lowerBound
//                let progress = duration > 0 ? CGFloat((viewModel.playerState.currentTime - range.lowerBound) / duration) : 0
//                let xOffset =  max(0, progress * width)
//                
//                ZStack(alignment: .leading) {
//                    Capsule()
//                        .fill(Color.gray.opacity(0.8))
//                        .frame(height: trackHeight)
//                    
//                    Capsule()
//                        .fill(Color.red)
//                        .frame(width: xOffset, height: trackHeight)
// 
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: thumbSize, height: thumbSize)
//                        .scaleEffect(isDragging ? 1.2 : 1.0)
//                        .offset(x: xOffset - thumbSize / 2)
//                        .contentShape(Rectangle()) // Ensures gesture works even if Circle is small
//                        .gesture(
//                            DragGesture(minimumDistance: 0)
//                                .updating($isDragging) { _, state, _ in
//                                    state = true
//                                }
//                                .onChanged { gesture in
//                                    let location = gesture.location.x
//                                    let percentage = min(max(0, location / width), 1)
//                                    let newValue = range.lowerBound + Double(percentage) * duration
//                                    viewModel.sliderTracking(time: newValue)
//                                }
//                                .onEnded { gesture in
//                                    print("ENDED") // <--- Try printing to confirm
//                                    let location = gesture.location.x
//                                    let percentage = min(max(0, location / width), 1)
//                                    let newValue = range.lowerBound + Double(percentage) * duration
//                                    viewModel.sliderEndedTracking(time: newValue)
//                                }
//                        )
//
//                    
//                }
//            }
//            
////            Text("\(timeString(from: viewModel.playerState.currentTime)) / \(timeString(from: viewModel.playerState.totalTime))")
//            Text(viewModel.getTimeLabel)
//                .font(.system(size: (isLandscape ? 14 : 12) * iconScale))
//                .foregroundColor(.white)
//                .padding(.bottom, 9 * iconScale)
//        }
//        .animation(.easeInOut, value: viewModel.playerState.currentTime)
//    }
//    
//    private func timeString(from timeInterval: TimeInterval) -> String {
//        let totalSeconds = Int(timeInterval)
//        let minutes = totalSeconds / 60
//        let seconds = totalSeconds % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
//}




//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: thumbSize, height: thumbSize)
//                        .scaleEffect(isDragging ? 1.2 : 1.0)
//                        .offset(x: xOffset - thumbSize / 2)
//                    //                        .gesture(
//                    //                            DragGesture(minimumDistance: 0)
//                    //                                .updating($isDragging) { gesture, state, _ in
//                    //                                    state = true
//                    //                                    if isDragging {
//                    //                                        let location = gesture.location.x
//                    //                                        let percentage = min(max(0, location / width), 1)
//                    //                                        let newValue = range.lowerBound + Double(percentage) * duration
//                    //                                        viewModel.sliderBeginTracking(time: newValue)
//                    //                                    } else {
//                    //                                        let location = gesture.location.x
//                    //                                        let percentage = min(max(0, location / width), 1)
//                    //                                        let newValue = range.lowerBound + Double(percentage) * duration
//                    //                                        viewModel.sliderEndedTracking(time: newValue)
//                    //                                    }
//                    //                                }
//                    //                                .onChanged { gesture in
//                    //                                    let location = gesture.location.x
//                    //                                    let percentage = min(max(0, location / width), 1)
//                    //                                    let newValue = range.lowerBound + Double(percentage) * duration
//                    //                                    viewModel.sliderEndedTracking(time: newValue)
//                    //
//                    //
//                    //                                }
//                    //                        )
//                        .gesture(
//                            DragGesture(minimumDistance: 0)
//                                .updating($isDragging) { _, state, _ in
//                                    state = true
//                                }
//                                .onChanged { gesture in
//                                    let location = gesture.location.x
//                                    let percentage = min(max(0, location / width), 1)
//                                    let newValue = range.lowerBound + Double(percentage) * duration
//                                    viewModel.sliderTracking(time: newValue)
//                                }
//                                .onEnded { gesture in
//                                    let location = gesture.location.x
//                                    let percentage = min(max(0, location / width), 1)
//                                    let newValue = range.lowerBound + Double(percentage) * duration
//                                    viewModel.sliderEndedTracking(time: newValue)
//                                }
//                        )

//
//struct CustomSwiftUISlider: View {
//    @ObservedObject var viewModel: PlayerControlsViewModel
//    let range: ClosedRange<Double> = 0...100 // fixed 0–100
//    @GestureState private var isDragging = false
//
//    private var isLandscape: Bool {
//        viewModel.isLandscape
//    }
//
//    private var iconScale: CGFloat {
//        UIDevice.isIPad ? 1.5 : 1.0
//    }
//
//    var body: some View {
//        VStack {
//            if viewModel.playerControlsType == .liveControls {
//                liveControls
//            } else {
//                nonLiveControls
//            }
//        }
//        .frame(height: 24)
//    }
//
//    var liveControls: some View {
//        HStack {
//            Spacer()
//            Button(action: viewModel.seekToLiveTapped) {
//                Text("LIVE")
//                    .font(.system(size: 12 * iconScale))
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 10 * iconScale)
//                    .padding(.vertical, 6 * iconScale)
//                    .background(
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(Color.red)
//                    )
//            }
//        }
//    }
//
//    var nonLiveControls: some View {
//        HStack(spacing: 19 * iconScale) {
//            GeometryReader { geometry in
//                let width = geometry.size.width
//                let thumbSize: CGFloat = 18 * iconScale
//                let trackHeight: CGFloat = 2.5 * iconScale
//
//                /// Assume playerState.percentage is 0–100, calculated externally
//                let progressPercent = min(max(viewModel.playerState.currentTime, 0), 100)
//                let xOffset = CGFloat(progressPercent / 100) * width
//
//                ZStack(alignment: .leading) {
//                    Capsule()
//                        .fill(Color.gray.opacity(0.8))
//                        .frame(height: trackHeight)
//
//                    Capsule()
//                        .fill(Color.red)
//                        .frame(width: xOffset, height: trackHeight)
//
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: thumbSize, height: thumbSize)
//                        .scaleEffect(isDragging ? 1.2 : 1.0)
//                        .offset(x: xOffset - thumbSize / 2)
//                        .contentShape(Rectangle())
//                        .gesture(
//                            DragGesture(minimumDistance: 0)
//                                .updating($isDragging) { _, state, _ in
//                                    state = true
//                                }
//                                .onChanged { gesture in
//                                    let location = gesture.location.x
//                                    let percent = min(max(0, location / width), 1)
//                                    let scaled = percent * 100
//                                    viewModel.sliderTracking(time: scaled)
//                                }
//                                .onEnded { gesture in
//                                    let location = gesture.location.x
//                                    let percent = min(max(0, location / width), 1)
//                                    let scaled = percent * 100
//                                    viewModel.sliderEndedTracking(time: scaled)
//                                }
//                        )
//                }
//            }
//
//            Text(viewModel.getTimeLabel)
//                .font(.system(size: (isLandscape ? 14 : 12) * iconScale))
//                .foregroundColor(.white)
//                .padding(.bottom, 9 * iconScale)
//        }
//        .animation(.easeInOut, value: viewModel.playerState.currentTime)
//    }
//}


//struct CustomSwiftUISlider: View {
//    @ObservedObject var viewModel: PlayerControlsViewModel
//    let range: ClosedRange<Double> = 0...100 // fixed 0–100
//    @GestureState private var isDragging = false
//
//    private var isLandscape: Bool {
//        viewModel.isLandscape
//    }
//
//    private var iconScale: CGFloat {
//        UIDevice.isIPad ? 1.5 : 1.0
//    }
//
//    var body: some View {
//        VStack {
//            if viewModel.playerControlsType == .liveControls {
//                liveControls
//            } else {
//                nonLiveControls
//            }
//        }
//        .frame(height: 24)
//    }
//
//    var liveControls: some View {
//        HStack {
//            Spacer()
//            Button(action: viewModel.seekToLiveTapped) {
//                Text("LIVE")
//                    .font(.system(size: 12 * iconScale))
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 10 * iconScale)
//                    .padding(.vertical, 6 * iconScale)
//                    .background(
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(Color.red)
//                    )
//            }
//        }
//    }
//
//    var nonLiveControls: some View {
//        HStack(spacing: 19 * iconScale) {
//            GeometryReader { geometry in
//                let width = geometry.size.width
//                let thumbSize: CGFloat = 18 * iconScale
//                let trackHeight: CGFloat = 2.5 * iconScale
//
//                // Current time is already 0-100, so we normalize it to 0-1 for positioning
//                let currentTime = min(max(viewModel.playerState.currentTime, 0), 100)
//                let normalizedProgress = currentTime / 100.0 // Convert 0-100 to 0-1
//                let xOffset = CGFloat(normalizedProgress) * width
//
//                ZStack(alignment: .leading) {
//                    // Background track
//                    Capsule()
//                        .fill(Color.gray.opacity(0.8))
//                        .frame(height: trackHeight)
//
//                    // Progress track
//                    Capsule()
//                        .fill(Color.red)
//                        .frame(width: xOffset, height: trackHeight)
//
//                    // Thumb
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: thumbSize, height: thumbSize)
//                        .scaleEffect(isDragging ? 1.2 : 1.0)
//                        .offset(x: xOffset - thumbSize / 2)
//                        .contentShape(Rectangle())
//                        .gesture(
//                            DragGesture(minimumDistance: 0)
//                                .updating($isDragging) { _, state, _ in
//                                    state = true
//                                }
//                                .onChanged { gesture in
//                                    let location = gesture.location.x
//                                    let normalizedPercent = min(max(0, location / width), 1) // 0-1
//                                    let timeValue = normalizedPercent * 100 // Convert to 0-100
//                                    viewModel.sliderTracking(time: timeValue)
//                                }
//                                .onEnded { gesture in
//                                    let location = gesture.location.x
//                                    let normalizedPercent = min(max(0, location / width), 1) // 0-1
//                                    let timeValue = normalizedPercent * 100 // Convert to 0-100
//                                    viewModel.sliderEndedTracking(time: timeValue)
//                                }
//                        )
//                }
//            }
//
//            Text(viewModel.getTimeLabel)
//                .font(.system(size: (isLandscape ? 14 : 12) * iconScale))
//                .foregroundColor(.white)
//                .padding(.bottom, 9 * iconScale)
//        }
//        .id("SliderValueID: \(viewModel.playerState.currentTime)")
//        .animation(.easeInOut, value: viewModel.playerState.currentTime)
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}


//struct CustomSwiftUISlider: View {
//    @ObservedObject var viewModel: PlayerControlsViewModel
//    let range: ClosedRange<Double> = 0...100 // fixed 0–100
//    @State private var isEditing = false
//    
//    private var isLandscape: Bool {
//        viewModel.isLandscape
//    }
//    
//    private var iconScale: CGFloat {
//        UIDevice.isIPad ? 1.5 : 1.0
//    }
//    
//    var body: some View {
//        VStack {
//            if viewModel.playerControlsType == .liveControls {
//                liveControls
//            } else {
//                nonLiveControls
//            }
//        }
//        .frame(height: 24)
//    }
//    
//    var liveControls: some View {
//        HStack {
//            Spacer()
//            Button(action: {
//                viewModel.seekToLiveTapped()
//            }) {
//                Text("LIVE")
//                    .font(.system(size: 12 * iconScale))
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 10 * iconScale)
//                    .padding(.vertical, 6 * iconScale)
//                    .background(
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(Color.red)
//                    )
//            }
//        }
//    }
//    
//    var nonLiveControls: some View {
//        HStack(spacing: 19 * iconScale) {
//            Slider(
//                value: Binding(
//                    get: {
//                        // Ensure we get a value between 0-100
//                        min(max(viewModel.playerState.currentTime, 0), 100)
//                    },
//                    set: { newValue in
//                        // Clamp the value to 0-100 range
//                        let clampedValue = min(max(newValue, 0), 100)
//                        if isEditing {
//                            viewModel.sliderTracking(time: clampedValue)
//                        }
//                    }
//                ),
//                in: range,
//                onEditingChanged: { editing in
//                    if editing {
//                        isEditing = true
//                    } else {
//                        isEditing = false
//                        let clampedValue = min(max(viewModel.playerState.currentTime, 0), 100)
//                        viewModel.sliderEndedTracking(time: clampedValue)
//                    }
//                }
//            )
//            .accentColor(.red) // This sets the progress color
//            .background(Color.gray.opacity(0.8)) // This sets the track color
//            .scaleEffect(y: iconScale) // Scale the slider height
//            
//            Text(viewModel.getTimeLabel)
//                .font(.system(size: (isLandscape ? 14 : 12) * iconScale))
//                .foregroundColor(.white)
//                .padding(.bottom, 9 * iconScale)
//        }
//        .animation(.easeInOut, value: viewModel.playerState.currentTime)
//    }
//}

//
//struct CustomSwiftUISlider: View {
//    @ObservedObject var viewModel: PlayerControlsViewModel
//    let range: ClosedRange<Double> = 0...100 // fixed 0–100
//    
//    // State for drag resistance
//    @State private var dragStartValue: Double = 0
//    @State private var isDragging: Bool = false
//    @State private var accumulatedDrag: Double = 0
//    
//    // Drag resistance factor - higher values require more drag for same change
//    private let dragResistance: Double = 3.0
//    
//    private var isLandscape: Bool {
//        viewModel.isLandscape
//    }
//    
//    private var iconScale: CGFloat {
//        UIDevice.isIPad ? 1.5 : 1.0
//    }
//    
//    var body: some View {
//        VStack {
//            if viewModel.playerControlsType == .liveControls {
//                liveControls
//            } else {
//                nonLiveControls
//            }
//        }
//        .frame(height: 24)
//    }
//    
//    var liveControls: some View {
//        HStack {
//            Spacer()
//            Button(action: viewModel.seekToLiveTapped) {
//                Text("LIVE")
//                    .font(.system(size: 12 * iconScale))
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 10 * iconScale)
//                    .padding(.vertical, 6 * iconScale)
//                    .background(
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(Color.red)
//                    )
//            }
//        }
//    }
//    
//    var nonLiveControls: some View {
//        HStack(spacing: 19 * iconScale) {
//            // Native Slider with custom appearance and drag resistance
//            Slider(
//                value: Binding(
//                    get: {
//                        isDragging ? dragStartValue + (accumulatedDrag / dragResistance) : viewModel.playerState.currentTime
//                    },
//                    set: { newValue in
//                        if !isDragging {
//                            // Direct setting when not dragging (programmatic updates)
//                            viewModel.sliderTracking(time: newValue)
//                        }
//                    }
//                ),
//                in: range
//            ) { isEditing in
//                // onEditingChanged callback
//                if isEditing && !isDragging {
//                    // Started dragging
//                    isDragging = true
//                    dragStartValue = viewModel.playerState.currentTime
//                    accumulatedDrag = 0
//                } else if !isEditing && isDragging {
//                    // Ended dragging
//                    let finalValue = dragStartValue + (accumulatedDrag / dragResistance)
//                    let clampedValue = min(max(finalValue, range.lowerBound), range.upperBound)
//                    
//                    viewModel.sliderEndedTracking(time: clampedValue)
//                    
//                    isDragging = false
//                    accumulatedDrag = 0
//                }
//            }
////            .simultaneousGesture(
////                // Custom drag gesture for resistance
////                DragGesture(minimumDistance: 0)
////                    .onChanged { gesture in
////                        if isDragging {
////                            // Calculate drag distance and apply resistance
////                            let dragDistance = gesture.location.x
////                            let sliderWidth: CGFloat = 200 // Approximate slider width, adjust as needed
////                            let percentChange = (dragDistance / sliderWidth) * 100
////                            
////                            accumulatedDrag = percentChange
////                            
////                            let newValue = dragStartValue + (accumulatedDrag / dragResistance)
////                            let clampedValue = min(max(newValue, range.lowerBound), range.upperBound)
////                            
////                            viewModel.sliderTracking(time: clampedValue)
////                        }
////                    }
////            )
//            .accentColor(.red) // Thumb and progress color
//            .background(
//                // Custom track styling
//                Capsule()
//                    .fill(Color.gray.opacity(0.8))
//                    .frame(height: 2.5 * iconScale)
//            )
////            .scaleEffect(isDragging ? 1.1 : 1.0) // Scale effect when dragging
//            .animation(.easeInOut(duration: 0.2), value: isDragging)
//            
//            Text(viewModel.getTimeLabel)
//                .font(.system(size: (isLandscape ? 14 : 12) * iconScale))
//                .foregroundColor(.white)
//                .padding(.bottom, 9 * iconScale)
//        }
//        .animation(.easeInOut, value: viewModel.playerState.currentTime)
//    }
//}
