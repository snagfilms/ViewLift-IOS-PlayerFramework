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
    var playbackToken:String
    var nextVideoList: [NextVideoList]?
}

struct NextVideoList:Codable {
    var videoId:String
}
