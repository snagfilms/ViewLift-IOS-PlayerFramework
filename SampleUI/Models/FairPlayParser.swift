//
//  FairPlayParser.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 24/02/26.
//  Copyright © 2026 Viewlift. All rights reserved.
//

import VLPlayerLib
import Foundation
/// Parses embedded FairPlay DRM JSON configuration into usable SDK models.
///
/// This utility class contains a **hardcoded FairPlay JSON configuration** and:
/// - Parses it into `DRMConfig` for license acquisition
/// - Extracts stream `URL` for playback
/// - Provides both as public static properties
///
/// Usage:
/// ```
/// let drmConfig = FairPlayParser.drmConfig
/// let streamUrl = FairPlayParser.streamUrl
/// ```
public final class FairPlayParser {
    
    /// Complete FairPlay JSON configuration (USANetwork demo stream)
    private static let fairPlayJSON: String = """
    
    """
    
    /// Internal JSON model matching FairPlay structure
    private struct FairPlayJSON: Decodable {
        let url: String
        let certificateUrl: String
        let licenseUrl: String
        let completeskd: String
        let licenseToken: String
    }
    
    /// Pre-parsed FairPlay configuration from embedded JSON
    private static let parsedConfig: FairPlayJSON? = {
        guard let data = fairPlayJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(FairPlayJSON.self, from: data)
    }()
    
    /// Stream URL extracted from FairPlay configuration (HLS master playlist)
    public static var streamUrl: String {
        parsedConfig?.url ?? ""
    }
    
    /// DRM configuration populated from parsed FairPlay JSON (license acquisition)
    public static var drmConfig: VLPlayer.DRMConfig? {
        guard let config = parsedConfig else {
            debugPrint("Failed to parse embedded FairPlay JSON configuration")
            return nil
        }
        return VLPlayer.DRMConfig(
            licenseUrl: config.licenseUrl,
            certificateUrl: config.certificateUrl,
            licenseToken: config.licenseToken,
            completeSkd: config.completeskd
        )
    }
}
