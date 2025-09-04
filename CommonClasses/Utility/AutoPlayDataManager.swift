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
        let items = [VLPlayer.StreamId(id: "stream1", url: "https://spinco.staging.asset.viewlift.com/Renditions/20250623/1750680676506_spinco_HD_TVE_CNBCSPORTO_03292025_A_7830k_mp4_CUSTOM_CODEC_TS_DRM_DASH_DRM/hls/master.m3u8"), VLPlayer.StreamId(id: "stream2", url: "https://spinco.staging.asset.viewlift.com/Renditions/20250710/1752155865323_spinco_HD_TVE_SURREALEST_303_04172025_7830k_mp4_CUSTOM_CODEC_TS_DRM_DASH_DRM/hls/master.m3u8")
        ]
        guard !items.isEmpty else { return nil }
        return VLPlayer.PlaybackList.streams(items)
    }
    
    func getMetadataFor(id: String) -> VLPlayer.StreamMetadata? {
        if id == "stream1"{
            let streamConfig = VLPlayer.StreamConfig(isLive: false, isDVR: nil)
            let drmConfig = VLPlayer.DRMConfig(licenseUrl: "https://spinco.staging.api.viewlift.com/v1/license/fairplay/acquire", certificateUrl: "https://spinco.staging.asset.viewlift.com/Certs/fairplay-Spinco.cer", licenseToken: "spinco|eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhbm9ueW1vdXNVc2VySWQiOiIiLCJhc3NldEtleSI6ImJhNmM2ZGFlLWNkMTgtNDE5ZC04YmI5LTcyYTljMTEyYzhkZSIsImNsaWVudElwIjoiMTIyLjE2MS41MC45IiwiY29udGVudElkIjoiMDc0MThiODYtODE4NC00NjZhLThkNTItZDBlM2Y4OGZkMzIwIiwiY291bnRyeUNvZGUiOiJJTiIsImRldmljZUlkIjoiMkMzODI0MkYtMTU0OS00QTg4LThFQTUtRTg1NjBDQTBGNUREIiwiZGV2aWNlVHlwZSI6Imlvc19pcGFkIiwiZHJtS2V5Um90YXRpb25FbmFibGVkIjpmYWxzZSwiZXhwIjoxNzU3MDE1ODk2LCJoZGNwIjoiIiwiaWF0IjoxNzU2OTcyNjk2LCJpc0xpdmVTdHJlYW0iOmZhbHNlLCJtZWRpYUxpdmVJZCI6IiIsIm1vbmV0aXphdGlvbk1vZGVscyI6W3sidHlwZSI6IlRWRSJ9XSwic2l0ZSI6InNwaW5jbyIsInNsIjoiIiwidGVlIjoiIiwidG9rZW5JZCI6IjFjN2ZiNDEzLWU3MjctNGUwMi04MmMxLWI0YTZjOThlYTdlNyIsInVzZXJJZCI6ImJlZWYzMGE1LTJmZDUtNGQ2Yy05NzU5LWEyOTdmMzM0YmNmNCJ9.P9zAuJS0kR1IE-CoI6GNzk1CEwz85-EQFywLLO08cJM", completeSkd: "ba6c6dae-cd18-419d-8bb9-72a9c112c8de")
            let contentData = VLPlayer.ContentData(contentTitle: "Title 1", contentDescription: "Description 1", thumbnail: "https://www.kasandbox.org/programming-images/avatars/leaf-blue.png")
            let metaData = VLPlayer.StreamMetadata(streamConfig: streamConfig, drmconfig: drmConfig, contentData: contentData)
            return metaData
        }else if id == "stream2"{
            let streamConfig = VLPlayer.StreamConfig(isLive: false, isDVR: nil)
            let drmConfig = VLPlayer.DRMConfig(licenseUrl: "https://spinco.staging.api.viewlift.com/v1/license/fairplay/acquire", certificateUrl: "https://spinco.staging.asset.viewlift.com/Certs/fairplay-Spinco.cer", licenseToken: "spinco|eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhbm9ueW1vdXNVc2VySWQiOiIiLCJhc3NldEtleSI6ImQ5NTQzMzYzLTg5OWMtNGE4Ny04Y2M3LTgwOTE4M2E3M2JiNCIsImNsaWVudElwIjoiMTIyLjE2MS41MC45IiwiY29udGVudElkIjoiYzMwZGNiMTAtMjQ1Ni00NzczLTgzZmItMmJlNzg2MDZmMDc4IiwiY291bnRyeUNvZGUiOiJJTiIsImRldmljZUlkIjoiMkMzODI0MkYtMTU0OS00QTg4LThFQTUtRTg1NjBDQTBGNUREIiwiZGV2aWNlVHlwZSI6Imlvc19pcGFkIiwiZHJtS2V5Um90YXRpb25FbmFibGVkIjpmYWxzZSwiZXhwIjoxNzU3MDE2MDA2LCJoZGNwIjoiIiwiaWF0IjoxNzU2OTcyODA2LCJpc0xpdmVTdHJlYW0iOmZhbHNlLCJtZWRpYUxpdmVJZCI6IiIsIm1vbmV0aXphdGlvbk1vZGVscyI6W3sidHlwZSI6IkZSRUUifV0sInNpdGUiOiJzcGluY28iLCJzbCI6IiIsInRlZSI6IiIsInRva2VuSWQiOiI1YjlmNjQwMi00ZjQ2LTQ2MWEtYWEyNC05NmVlNWNiNzFkOTgiLCJ1c2VySWQiOiJiZWVmMzBhNS0yZmQ1LTRkNmMtOTc1OS1hMjk3ZjMzNGJjZjQifQ.jRgdoWGWX-TTrRn03CfpOt0sqI-c2jmPIn4yl4CPKU4", completeSkd: "d9543363-899c-4a87-8cc7-809183a73bb4")
            let contentData = VLPlayer.ContentData(contentTitle: "Title 2", contentDescription: "Description 2", thumbnail: nil)
            let metaData = VLPlayer.StreamMetadata(streamConfig: streamConfig, drmconfig: drmConfig, contentData: contentData)
            return metaData
        }else{
            return nil
        }
    }
    
    func getAutoPlayVideoIdList() -> VLPlayer.PlaybackList? {
        let videoIds = [String]()
        
        guard !videoIds.isEmpty else { return nil }
        
        let videos = videoIds.map { VLPlayer.VideoId($0) }
        
        return .videos(videos)
    }
    
}
