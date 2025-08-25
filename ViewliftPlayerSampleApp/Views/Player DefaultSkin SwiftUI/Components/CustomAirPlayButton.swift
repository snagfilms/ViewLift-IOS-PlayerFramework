//
//  CustomAirPlayButton.swift
//  VLPlayer
//
//  Created by Japneet Singh on 04/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//


import SwiftUI
import AVKit

// MARK: - Custom AirPlay Button that can be triggered programmatically
struct CustomAirPlayButton: UIViewRepresentable {
    @Binding var shouldPresent: Bool
    @Binding var isAirPlayActive: Bool
    var onRouteChange: ((Bool) -> Void)?
    
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.prioritizesVideoDevices = true
        routePickerView.tintColor = .gray
        routePickerView.activeTintColor = .white
        routePickerView.delegate = context.coordinator
        
        // Setup audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
        
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        if shouldPresent {
            DispatchQueue.main.async {
                // Find the button and trigger it
                if let routePickerButton = uiView.subviews.first(where: { $0 is UIButton }) as? UIButton {
                    routePickerButton.sendActions(for: .touchUpInside)
                }
                self.shouldPresent = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVRoutePickerViewDelegate {
        var parent: CustomAirPlayButton
        
        init(_ parent: CustomAirPlayButton) {
            self.parent = parent
        }
        
        func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
            // Handle route picker presentation start
        }
        
        func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
            let audioSession = AVAudioSession.sharedInstance()
            let currentRoute = audioSession.currentRoute
            
            var isAirPlayActive = false
            for outputPort in currentRoute.outputs {
                if outputPort.portType == .airPlay {
                    isAirPlayActive = true
                    break
                }
            }
            
            DispatchQueue.main.async {
                self.parent.isAirPlayActive = isAirPlayActive
                self.parent.onRouteChange?(isAirPlayActive)
            }
        }
    }
}


struct RouteButtonView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.tintColor = .red // Set any tint color as per your design
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        // No update needed
    }
}
