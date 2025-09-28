//
//  NetworkReachability.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 27/09/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//


import Network

/// Simple reachability manager to check network status (WiFi, Cellular).
final class NetworkReachability {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkReachabilityMonitor")
    
    // These reflect the current network state.
    private(set) var isConnected: Bool = false
    private(set) var isOnWiFi: Bool = false
    private(set) var isOnCellular: Bool = false
    
    init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
            self?.isOnWiFi = path.usesInterfaceType(.wifi)
            self?.isOnCellular = path.usesInterfaceType(.cellular)
        }
        monitor.start(queue: queue)
    }
    
    deinit { monitor.cancel() }
    
    func getRechabilityStatus() -> String {
        if !isConnected {
            return "Offline"
        } else {
            return self.isOnWiFi ? "Wifi" : "Cellular"
        }
    }
}

/// Usage:
///
/// let reachability = NetworkReachability()
/// let online = reachability.isConnected       // true if any network is available
/// let wifi    = reachability.isOnWiFi         // true if connected to WiFi
/// let cellular = reachability.isOnCellular    // true if connected to Cellular
