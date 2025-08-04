//
//  VLVideoResponseModel.swift
//  ViewliftPlayerSampleApp
//
//  Created by Nexgen on 03/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import Foundation

// MARK: - VLVideoResponseModel
struct VLVideoResponseModel: Codable {
    let siteName: String?
    let siteId: String?
    let playable: Bool?
    let success: Bool?
    let video: VLVideo?
    let plans: [VLPlan]?
}

// MARK: - Video
struct VLVideo: Codable {
    let id: String?
    let title: String?
    let monetizationModels: [VLMonetizationModel]?
    let streamingInfo: VLStreamingInfo?
    let publishDate: TimeInterval?
    let contentType: String?
    let mediaType: String?
}

// MARK: - Monetization Model
struct VLMonetizationModel: Codable {
    let id: String?
    let type: String?
}

// MARK: - Streaming Info
struct VLStreamingInfo: Codable {
    let isLiveStream: Bool?
}

// MARK: - Plan
struct VLPlan: Codable {
    let name: String?
}

