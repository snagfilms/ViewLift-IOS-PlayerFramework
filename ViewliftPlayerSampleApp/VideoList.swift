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
    var vlToken:String
    var nextVideoList: [NextVideoList]?
    var apiBaseUrl: String
    var beaconBaseUrl: String?
    var xApiKey: String
}

struct NextVideoList:Codable {
    var videoId:String
}
