//
//  UserManager.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 03/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import Foundation
#if os(iOS)
import VLAuthentication
#else
import VLAuthentication_tvOS
#endif

final class UserManager {
    static let shared = UserManager()
    private init() {}
    
    fileprivate let kUserIdentityKey = "kUserIdentityKey"

    var userIdentity: VLUserIdentity? {
        get {
            guard let data = UserDefaults.standard.data(forKey: kUserIdentityKey) else { return nil }
            let decoder = JSONDecoder()
            return try? decoder.decode(VLUserIdentity.self, from: data)
        }
        set {
            let encoder = JSONEncoder()
            if let value = newValue, let encoded = try? encoder.encode(value) {
                UserDefaults.standard.set(encoded, forKey: kUserIdentityKey)
            } else {
                // Remove on nil
                UserDefaults.standard.removeObject(forKey: kUserIdentityKey)
            }
        }
    }
}
