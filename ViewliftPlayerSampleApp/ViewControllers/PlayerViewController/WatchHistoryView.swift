//
//  WatchHistoryView.swift
//  ViewliftPlayerSampleApp
//
//  Created by Abhinav Saldi on 6/4/26.
//  Copyright © 2026 Viewlift. All rights reserved.
//

import SwiftUI

// MARK: - Watch History Data Model
/// Shared observable object that can be accessed from anywhere in the app
class WatchHistoryData: ObservableObject {
    static let shared = WatchHistoryData()
    
    @Published var watchedTime: Int = 0
    @Published var watchedPercentage: Double = 0
    @Published var doneWatching: Bool = false
    
    private init() {}
    
    /// Update all watch history values at once
    func update(watchedTime: Int, watchedPercentage: Double, doneWatching: Bool) {
        self.watchedTime = watchedTime
        self.watchedPercentage = watchedPercentage
        self.doneWatching = doneWatching
    }
    
    /// Reset all values to default
    func reset() {
        watchedTime = 0
        watchedPercentage = 0
        doneWatching = false
    }
}

// MARK: - Delegate Protocol
protocol WatchHistoryDelegate: AnyObject {
    func didTapApply(isEnabled: Bool, interval: String, threshold: String, resume: String)
    func updateWatchHistory(_ isEnabled: Bool)
}

// MARK: - Watch History Configuration View
struct WatchHistoryView: View {
    
    // MARK: - Properties
    weak var delegate: WatchHistoryDelegate?
    
    @State private var isEnabled: Bool = true
    @State private var interval: String = "30"
    @State private var threshold: String = "95"
    @State private var resume: String = "0"
    
    // Use StateObject to observe the shared data model
    @StateObject private var watchHistoryData = WatchHistoryData.shared
    
    // Keep bindings for backward compatibility (optional)
    @Binding var watchedTime: Int
    @Binding var watchedPercentage: Double
    @Binding var doneWatching: Bool
    var iOS: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            
            // Enable Toggle
            HStack {
                // Title
                Text("Watch History")
                    .font(.system(size: (iOS ? 22 : 34), weight: .bold))
                    .foregroundStyle(.black)
                
                Spacer()

                Text("Enable")
                    .font(.system(size: (iOS ? 16 : 22)))
                    .foregroundColor(.black)
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .tint(.green)
                    .onChange(of: isEnabled) { newValue in
                        delegate?.updateWatchHistory(newValue)
                    }
                    .foregroundColor(.black)
            }
            .padding(.top, 20)
            .padding(.vertical, (iOS ? 10 : 0))
            
            // Input Fields Row - Highlight when enabled
            HStack(spacing: 15) {
                // Interval Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interval (sec)")
                        .font(.system(size: iOS ? 13 : 22))
                        .foregroundColor(.black)
                    
                    TextField("30", text: $interval)
                        .textFieldStyle(.plain)
                        .keyboardType(.numberPad)
                        .padding(8)
                        .background(Color(white: 0.95))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
                
                // Threshold Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Threshold (%)")
                        .font(.system(size: iOS ? 13 : 22))
                        .foregroundColor(.black)
                    
                    TextField("5", text: $threshold)
                        .textFieldStyle(.plain)
                        .keyboardType(.numberPad)
                        .padding(8)
                        .background(Color(white: 0.95))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
                #if os(tvOS)
                // Resume Field - Highlight when enabled
                VStack(alignment: .leading, spacing: 8) {
                    Text("Resume (sec)")
                        .font(.system(size: 22))
                        .foregroundColor(.black)
                    
                    TextField("0", text: $resume)
                        .textFieldStyle(.plain)
                        .keyboardType(.numberPad)
                        .padding(8)
                        .background(Color(white: 0.95))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
                #endif
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.5)
            
            #if os(iOS)
            // Resume Field - Highlight when enabled
            VStack(alignment: .leading, spacing: 8) {
                Text("Resume (sec)")
                    .font(.system(size: 13))
                    .foregroundColor(.black)
                
                TextField("0", text: $resume)
                    .textFieldStyle(.plain)
                    .keyboardType(.numberPad)
                    .padding(8)
                    .background(Color(white: 0.95))
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.5)
            #endif
            
            // Apply Button - Highlight when enabled
            Button(action: handleApplyTap) {
                Text("Apply")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.4, green: 0.2, blue: 0.8))
                    .cornerRadius(10)
            }
            .padding(.top, (iOS ? 10 : 0))
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.5)
            // Watch History Update Status - Highlight when enabled
            VStack(alignment: .leading, spacing: 8) {
                Text("Watch history update:")
                    .font(.system(size: (iOS ? 17 : 24), weight: .semibold))
                    .foregroundColor(.black)
                
                Text("watchedTime=\(watchHistoryData.watchedTime)s, watchedPercentage=\(watchHistoryData.watchedPercentage.isFinite ? Int(watchHistoryData.watchedPercentage) : 0)%, doneWatching=\(watchHistoryData.doneWatching ? "true" : "false")")
                    .font(.system(size: (iOS ? 15 : 22)))
                    .foregroundColor(.black)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.95, green: 0.95, blue: 0.97))
            .cornerRadius(10)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.5)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isEnabled)
        .onAppear {
            syncBindingsToObservable()
        }
        .onChange(of: watchHistoryData.watchedTime) { newValue in
            watchedTime = newValue
        }
        .onChange(of: watchHistoryData.watchedPercentage) { newValue in
            watchedPercentage = newValue
        }
        .onChange(of: watchHistoryData.doneWatching) { newValue in
            doneWatching = newValue
        }
        .background(.white)
    }
    
    // MARK: - Helper Methods
    
    /// Syncs the binding values to the observable object
    private func syncBindingsToObservable() {
        watchHistoryData.watchedTime = watchedTime
        watchHistoryData.watchedPercentage = watchedPercentage
        watchHistoryData.doneWatching = doneWatching
    }
    
    // MARK: - Actions
    private func handleApplyTap() {
        delegate?.didTapApply(
            isEnabled: isEnabled,
            interval: interval,
            threshold: threshold,
            resume: resume
        )
        // Dismiss keyboard in SwiftUI
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Public Methods
    
    /// Updates the interval value
    func updateInterval(_ value: String) {
        self.interval = value
    }
    
    /// Updates the threshold value
    func updateThreshold(_ value: String) {
        self.threshold = value
    }
    
    /// Updates the resume value
    func updateResume(_ value: String) {
        self.resume = value
    }
    
    /// Updates the enabled state
    func updateEnabled(_ value: Bool) {
        self.isEnabled = value
    }
    
    /// Gets current configuration as dictionary
    func getCurrentConfiguration() -> [String: Any] {
        return [
            "isEnabled": isEnabled,
            "interval": Int(interval) ?? 0,
            "threshold": Int(threshold) ?? 0,
            "resume": Int(resume) ?? 0
        ]
    }
}
