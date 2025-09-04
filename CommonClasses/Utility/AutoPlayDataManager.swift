//
//  AutoPlayDataManager.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 31/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import Foundation
import VLPlayerLib

class AutoPlayDataManager {
    
    /// Stores metadata for streams only (URLs)
    var autoPlayList: [String: VLPlayer.StreamMetadata] = [:]
    
    init() {
        
        if let data = self.getAutoPlaybackList(){
            self.autoPlayList = data
        }
    }
    
    func getAutoPlaybackList() -> [String: VLPlayer.StreamMetadata]?{
        let playbackList  = self.getAutoPlayUrlList()
        if case let .streams(streams) = playbackList {
            return  self.getAutoPlayListMetaData(for: streams)
        }
       return nil
    }
    
    /// Prepares autoPlayList for given streams
    func getAutoPlayListMetaData(for streams: [VLPlayer.StreamId]) -> [String: VLPlayer.StreamMetadata]{
        var metaDataList: [String: VLPlayer.StreamMetadata] = [:]
        for stream in streams{
            metaDataList[stream.id] = self.getMetadataFor(id: stream.id)
        }
        return metaDataList
    }
    
    
    func getAutoPlayUrlList() -> VLPlayer.PlaybackList? {
        let items = [VLPlayer.StreamId(id: "stream1", url: "https://cnbcawsmpvod.akamaized.net/out/v1/066a8886bd124848a72eb770e89ba5b7/54fbf64382f04b94bb69340d5528ff8b/26cdcccd8cb84f5398bc0124836d47ee/master.m3u8"), VLPlayer.StreamId(id: "stream2", url: "https://cdn-vl-gcp-l-01.vos360.video/Content/HLS_HLS_CLEAR/Live/channel(886a397d-ff30-4021-eb16-bb73c658c033)/index.m3u8")
        ]
        guard !items.isEmpty else { return nil }
        return VLPlayer.PlaybackList.streams(items)
    }
    
    func getMetadataFor(id: String) -> VLPlayer.StreamMetadata? {
        if id == "stream1"{
            let streamConfig = VLPlayer.StreamConfig(isLive: false, isDVR: nil)
            let contentData = VLPlayer.ContentData(contentTitle: "Title 1", contentDescription: "Description 1", thumbnail: nil)
            let metaData = VLPlayer.StreamMetadata(streamConfig: streamConfig, drmconfig: nil, contentData: contentData)
            return metaData
        }else if id == "stream2"{
            let streamConfig = VLPlayer.StreamConfig(isLive: true, isDVR: nil)
            let contentData = VLPlayer.ContentData(contentTitle: "Title 2", contentDescription: "Description 2", thumbnail: nil)
            let metaData = VLPlayer.StreamMetadata(streamConfig: streamConfig, drmconfig: nil, contentData: contentData)
            return metaData
        }else{
            return nil
        }
    }
    
    func getAutoPlayVideoIdList() -> VLPlayer.PlaybackList? {
        let videoIds = ["a03595b8-219b-4706-9e21-376b3da3ac93", "c30dcb10-2456-4773-83fb-2be78606f078"]
        
        guard !videoIds.isEmpty else { return nil }
        
        let videos = videoIds.map { VLPlayer.VideoId($0) }
        
        return VLPlayer.PlaybackList.videos(videos)
    }
    
}
