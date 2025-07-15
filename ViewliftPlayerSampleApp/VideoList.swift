//
//  VideoList.swift
//  ViewliftPlayerSampleApp
//
//  Created by Gaurav Vig on 16/11/21.
//  Copyright © 2021 Viewlift. All rights reserved.
//

import Foundation

struct VideoList:Decodable {
    var videoId:String
    var streamUrl:String?
    let vlToken:String
    var nextVideoList: [NextVideoList]?
    let apiBaseUrl: String
    let beaconBaseUrl: String?
    let xApiKey: String
    let partnerApiBaseUrl: String
    let site: String
    let drmConfig: DRMConfigAsset?
    func checkForConfigurationErrorMessage() -> String?{
        if apiBaseUrl.contains("xxxxx") && vlToken.contains("xxxxx") {
            return "Please set the API base URL and ViewLift token in the VideoList json file."
        }
        else if apiBaseUrl.contains("xxxxx") {
            return "Please set the API base URL in the VideoList json file."
        }else if vlToken.contains("xxxxx") {
            return "Please set the ViewLift token in the VideoList json file."
        }
        return nil
        
    }
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
