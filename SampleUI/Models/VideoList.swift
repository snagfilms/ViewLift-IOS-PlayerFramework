//
//  VideoList.swift
//  ViewliftPlayerSampleApp
//
//  Created by Gaurav Vig on 16/11/21.
//  Copyright © 2021 Viewlift. All rights reserved.
//

import Foundation

protocol VideoListProtocol {
    var videoList:VideoList? {get set}
    func readVideoList()
}

enum PlayerUIOptions: String {
    case defaultControl = "Default sdk controls"
    case customControl = "Custom controls"
    case debugLogEnabled = "Debug logs enabled"
    case customControlWithDebugLog = "Custom controls and debug logs enabled"
    case customControlWithCustomSeekDuration = "Custom controls and custom seek duration"
    case adsEnabled = "Ads Enabled"
    case playStreamURL = "Play Stream URL"
    case playASATURL = "Play ASAT URL"
    case exploreMore = "Explore Player SDK - Use Cases"
    case verticalPlayer = "Vertical Video Player"
}

class ReadFromLocalJson:VideoListProtocol {
    var videoList: VideoList?
    
    func readVideoList() {
        if let path = Bundle.main.path(forResource: "configs", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                self.videoList = try JSONDecoder().decode(VideoList.self, from: data)
            } catch {
                debugPrint("Parsing Error configs.json", error.localizedDescription)
            }
        }
    }
}

struct VideoList:Decodable {
    var videoId:String
    var channelId: [String]
    var streamUrl:String?
    var nextVideoList: [NextVideoList]?
    let apiBaseUrl: String
    let beaconBaseUrl: String?
    let xApiKey: String
    let partnerApiBaseUrl: String
    let domain: String
    let drmConfig: DRMConfigAsset?
    let authKeys: AuthKeys
    func checkForConfigurationErrorMessage() -> String?{
        if apiBaseUrl.contains("xxxxx") {
            return "Please set the API base URL and ViewLift token in the VideoList json file."
        }
        else if apiBaseUrl.contains("xxxxx") {
            return "Please set the API base URL in the VideoList json file."
        }
        
        return nil
        
    }
}

struct AuthKeys: Codable {
    let siteId: String
    let apiBaseEndpoint: String
}

struct NextVideoList:Codable {
    var videoId:String
}

struct DRMConfigAsset: Codable {
    let licenseUrl:String
    let certificateUrl:String
    let licenseToken:String
    let completeskd:String
}
