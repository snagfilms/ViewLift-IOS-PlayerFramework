//
//  to.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 07/11/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
import Foundation

extension VLContentInfoAnalytics {
    
    // MARK: - JSON String Initializer
    
    /// Initialize VLContentInfoAnalytics from JSON string
    /// - Parameter jsonString: JSON string to parse
    /// - Throws: DecodingError if JSON parsing fails
    public convenience init(jsonString: String) throws {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "VLContentInfoAnalytics", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string encoding"])
        }
        
        try self.init(jsonData: jsonData)
    }
    
    /// Initialize VLContentInfoAnalytics from JSON data
    /// - Parameter jsonData: JSON data to parse
    /// - Throws: DecodingError if JSON parsing fails
    public convenience init(jsonData: Data) throws {
        let decoder = JSONDecoder()
        let response = try decoder.decode(VideoResponse.self, from: jsonData)
        
        // Map the decoded response to VLContentInfoAnalytics properties
        self.init(
            id: response.id,
            title: response.headline,
            durationInSeconds: nil,
            airDate: response.published,
            playbackUrl: response.videoUrl,
            streamType: false ? "live" : "vod",
            videonetwork: response.brand,
 isLive: false,
            subTitle: response.summary.isEmpty ? nil : response.summary,
 assetId: response.mpxId,
            videoguid: response.guid
        )
    }
    
    // MARK: - Private Decoding Models
    
    /// Private struct to decode the incoming JSON structure
    private struct VideoResponse: Decodable {
        let id: String
        let guid: String
        let brand: String?
        let headline: String
        let published: String
        let duration: Duration?
        let summary: String
        let videoUrl: String?
        let mpxId: String?
        
        struct Duration: Decodable {
            let isLive: Bool
            let timeInterval: Double
        }
        
        private enum CodingKeys: String, CodingKey {
            case id
            case guid
            case brand
            case headline
            case published
            case duration
            case summary
            case videoUrl
            case mpxId
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            id = try container.decode(String.self, forKey: .id)
            guid = try container.decode(String.self, forKey: .guid)
            brand = try container.decodeIfPresent(String.self, forKey: .brand)
            headline = try container.decode(String.self, forKey: .headline)
            published = try container.decode(String.self, forKey: .published)
            duration = try? container.decode(Duration.self, forKey: .duration)
            summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
            videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
            mpxId = try container.decodeIfPresent(String.self, forKey: .mpxId)
        }
    }
}
