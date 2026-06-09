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
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text("Watch History")
                .font(.system(size: 34, weight: .bold))
                .padding(.top, 20)
            
            // Enable Toggle
            HStack {
                Text("Enable")
                    .font(.system(size: 17))
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .tint(.green)
                    .onChange(of: isEnabled) { newValue in
                        delegate?.updateWatchHistory(newValue)
                    }
            }
            .padding(.vertical, 10)
            
            // Input Fields Row - Highlight when enabled
            HStack(spacing: 15) {
                // Interval Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interval (sec)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    TextField("30", text: $interval)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
                
                // Threshold Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Threshold (%)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    TextField("5", text: $threshold)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.5)
            
            // Resume Field - Highlight when enabled
            VStack(alignment: .leading, spacing: 8) {
                Text("Resume (sec)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                TextField("0", text: $resume)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.5)
            
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
            .padding(.top, 10)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.5)
            
            // Watch History Update Status - Highlight when enabled
            VStack(alignment: .leading, spacing: 8) {
                Text("Watch history update:")
                    .font(.system(size: 17, weight: .semibold))
                
                Text("watchedTime=\(Int(watchHistoryData.watchedTime))s, watchedPercentage=\(Int(watchHistoryData.watchedPercentage))%, doneWatching=\(watchHistoryData.doneWatching ? "true" : "false")")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
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
