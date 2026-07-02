//
//  ChapteringCommonFile.swift
//  ViewliftPlayerSampleApp
//
//  Created by Devendra Gaur on 02/07/26.
//  Copyright © 2026 Viewlift. All rights reserved.
//
import UIKit
import Foundation


struct ChapteringCuePointResponse: Decodable {
    let items: Items

    enum CodingKeys: String, CodingKey {
        case items = "Items"
    }

    struct Items: Decodable {
        let segments: [ChapteringCuePoint]

        enum CodingKeys: String, CodingKey {
            case segments = "Segments"
        }
    }
}

struct ChapteringCuePoint: Codable {
    let startTime: Double
    let label: String
    let thumbnail: String?
    let eventStartUtc: String?
    let origLength: Double?
    let stocks: String?

    enum CodingKeys: String, CodingKey {
        case startTime = "StartTime"
        case label = "Label"
        case origLength = "OrigLength"
        case thumbnail = "OriginalThumbnailLocation"
        case eventStartUtc = "event_start_utc"
        case stocks = "Stocks"
    }
}


extension UIViewController{
    func todayDate(preservingTimeFrom timeText: String?) -> Date? {
        guard let timeText = timeText?.trimmingCharacters(in: .whitespaces), !timeText.isEmpty else {
            return nil
        }
        let components = timeText.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]), (0...23).contains(hour),
              let minute = Int(components[1]), (0...59).contains(minute) else {
            return nil
        }
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = 0
        return calendar.date(from: dateComponents)
    }
    
    func chapteringDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }
    
}
