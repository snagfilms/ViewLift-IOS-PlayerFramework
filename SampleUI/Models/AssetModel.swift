//
//  AssetModel.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 22/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import Foundation

struct AssetModel {
    let title: String
    let subtitle: String?
    let playbackType: PlaybackType
    let isExternal: Bool?
    let staticContentId: String?
    let isLive: Bool?
    let isDVR: Bool?
    let channelId: [String]?
}

extension AssetModel: Codable {
    enum CodingKeys: String, CodingKey {
        case title, subtitle, videoId, url, isExternal, staticContentId, isLive, isDVR, channelId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        channelId = try container.decodeIfPresent([String].self, forKey: .channelId)
        isExternal = try container.decodeIfPresent(Bool.self, forKey: .isExternal)
        staticContentId = try container.decodeIfPresent(String.self, forKey: .staticContentId)
        isLive = try container.decodeIfPresent(Bool.self, forKey: .isLive)
        isDVR = try container.decodeIfPresent(Bool.self, forKey: .isDVR)
        let url = try container.decodeIfPresent(String.self, forKey: .url)
        let videoId = try container.decodeIfPresent(String.self, forKey: .videoId)

        if let url = url {
            playbackType = .url(url)
        } else if let videoId = videoId {
            playbackType = .videoId(videoId)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .url, in: container, debugDescription: "Expected either 'url' or 'videoId' to be present.")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)

        switch playbackType {
        case .url(let url):
            try container.encode(url, forKey: .url)
        case .videoId(let videoId):
            try container.encode(videoId, forKey: .videoId)
        }
    }
}

extension AssetModel {
    var contentIdentifier: String? {
        switch playbackType {
        case .url(let url):
            return url.isEmpty ? nil : url
        case .videoId(let id):
            return id.isEmpty ? nil : id
        }
    }
}
