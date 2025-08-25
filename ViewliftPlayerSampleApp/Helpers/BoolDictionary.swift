//
//  BoolDictionary.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 17/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//


actor AnalyticsAdDictionary {
    private var storage: [String: Bool] = [:]

    // Read
    func get(_ key: String) -> Bool? {
        storage[key]
    }

    // Write
    func set(_ key: String, _ value: Bool) {
        storage[key] = value
    }

    // Remove
    func remove(_ key: String) {
        storage.removeValue(forKey: key)
    }

    // Snapshot of all values (copied out)
    var all: [String: Bool] {
        storage
    }

    // Example of an atomic read-modify-write
    func toggle(_ key: String, default defaultValue: Bool = false) -> Bool {
        let new = !(storage[key] ?? defaultValue)
        storage[key] = new
        return new
    }
}
