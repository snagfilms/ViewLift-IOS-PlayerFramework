//
//  TokenIdentity.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 03/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//


import Foundation

func isJWTExpired(_ jwt: String) -> Bool {
    let segments = jwt.components(separatedBy: ".")
    guard segments.count == 3,
          let payloadData = Data(base64Encoded: padBase64(segments[1]), options: .ignoreUnknownCharacters),
          let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
          let exp = payload["exp"] as? TimeInterval else {
        return true
    }

    let currentTimestamp = Date().timeIntervalSince1970
    return exp < currentTimestamp
}

// Helper for base64url padding
func padBase64(_ base64: String) -> String {
    var padded = base64.replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let remainder = padded.count % 4
    if remainder > 0 {
        padded += String(repeating: "=", count: 4 - remainder)
    }
    return padded
}
