//
//  PlayerViewController_iOS+AutoPlay.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 25/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import Foundation
import VLPlayerLib
import UIKit

extension PlayerViewController_iOS {
    
    /// This is called when AutoPlay UI is dismissed. This is called for default UI
    func autoPlayUIDismissed(isPlayingNextContent: Bool) {
        if isPlayingNextContent{
            // nextcontent will play and ui dismissed
        }else{
            // ui dismissed
        }
    }
    
    /// This is called when Next Video with URL is about to play. You need to pass all the Metadata required to play this URL.Here you can update your AutoPlay UI with the new content.
    func autoPlayMetadataProvider(streamId: String) -> VLPlayer.StreamMetadata? {
        let data =  autoPlayListdataManager?.autoPlayList[streamId]
        autoPlayView?.updateView(data: data?.contentData)
        return data
    }
}

extension PlayerViewController_iOS{
    
    func createAutoPlayMetaData(){
        autoPlayListdataManager = AutoPlayDataManager()
    }
    
    private func createAutoPlayView() -> AutoPlayView {
        let autoPlay = AutoPlayView()
        autoPlay.translatesAutoresizingMaskIntoConstraints = false
        
        autoPlay.onPlay = { [weak self] in
            debugPrint("AutoPlayView Play button tapped")
            self?.removeAutoPlayView()
            self?.vlPlayer.playNextVideo()
        }
        
        autoPlay.onClose = { [weak self] in
            debugPrint("AutoPlayView Closed autoplay")
            self?.removeAutoPlayView()
        }
        
        autoPlay.onAutoPlay = { [weak self] in
            debugPrint("AutoPlayView finished, play next video")
            self?.removeAutoPlayView()
            self?.vlPlayer.playNextVideo()
        }
        self .autoPlayView = autoPlay
        return autoPlay
    }
    
    private func removeAutoPlayView() {
        autoPlayView?.removeFromSuperview()
    }
    
    /// Returns the AutoPlay configuration based on the type
    internal func getAutoPlayConfig(type: Configuration) -> VLPlayer.AutoPlayConfiguration?{
        switch type {
            
        case .default:
            return VLPlayer.AutoPlayConfiguration.default()
        case .customTheme:
            return VLPlayer.AutoPlayConfiguration.default(countdown: 15, theme: VLPlayer.AutoPlayTheme())
        case .custom:
            return VLPlayer.AutoPlayConfiguration.custom(view: createAutoPlayView())// Your view
        default :
            return VLPlayer.AutoPlayConfiguration.disabled
        }
        
    }
    
}
