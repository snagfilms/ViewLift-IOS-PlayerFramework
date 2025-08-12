//
//  PlayerViewController_iOS+FullScreenPlayer.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

extension PlayerViewController_iOS: FullScreenDelegate {
    
    func onFullScreenChange(currentTime: Double, isFullScreen: Bool, playerTag: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.isFullScreen = isFullScreen
        
        if isFullScreen {
            presentFullScreenPlayer()
        } else {
            dismissFullScreenPlayer()
        }
    }
    
    private func presentFullScreenPlayer() {
        vlPlayer.getVideoPlayerView()?.removeFromSuperview()
        
        fullScreenView = FullScreenPlayerViewController()
        fullScreenView?.modalPresentationStyle = .fullScreen
        fullScreenView?.view.frame = UIScreen.main.bounds
        
        present(fullScreenView!, animated: false) { [weak self] in
            self?.configureFullScreenControls()
        }
        
        if let playerView = vlPlayer.getVideoPlayerView() {
            fullScreenView?.loadPlayerView(playerView: playerView)
        }
    }
    
    private func dismissFullScreenPlayer() {
        self.fullScreenView?.dismiss(animated: false, completion: {
            self.videoPlayerControlsView?.frame = self.vlPlayer.getVideoPlayerView()?.frame ?? .zero
            self.videoPlayerControlsView?.updateControls(with: .small)
            self.videoPlayerControlsView?.videoPlayer?.setPlayerFitToSmallScreen(frame: .zero)
            
            if let playerView = self.vlPlayer.getVideoPlayerView() {
                self.addPlayer(playerView: playerView)
            }
            
        })
    }
    
    private func configureFullScreenControls() {
        videoPlayerControlsView?.frame = vlPlayer.getVideoPlayerView()?.frame ?? .zero
        videoPlayerControlsView?.updateControls(with: .full)
        videoPlayerControlsView?.videoPlayer?.setPlayerFitToFullScreen()
    }
    
    func fullScreenViewRemoved(playerTag: String) {
        vlPlayer.getVideoPlayerView()?.removeFromSuperview()
        vlPlayer.videoPlayerDelegate = self
        vlPlayer.getVideoPlayerView()?.frame = playerFrame
    }
}
