//
//  PlayerViewController_tvOS.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 17/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit
import VLPlayerLib
import VLBeaconLib

class PlayerViewController: UIViewController {
    private let playerContainerView = UIView()
    
    var streamUrl: String?
    var videoId: String?
    var entitlementData: VLPlayer.EntitlementData?
    var drmConfig: VLPlayer.DRMConfig?
    var videoList: VideoList!
    var playerOptionSelected:PlayerUIOptions!
    var vlPlayer: VLPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        playerContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerContainerView)
        NSLayoutConstraint.activate([
            playerContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playerContainerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 9.0/16.0)
        ])
        let featureSupported = getPlayerFeaturesSupported()
        let vlBaseUrl = self.videoList.apiBaseUrl
        let vlBeaconURL: String? = self.videoList.beaconBaseUrl
        let vlToken = self.videoList.vlToken
        
        var videoPlayerControlsView: UIView? = nil
        if playerOptionSelected == .playStreamURL || playerOptionSelected == .playASATURL{
            let playerLicenseKey: String? = ""
            let analyticsLicenseKey: String? = ""
            let userId: String? = nil
            if let playerLicenseKey = playerLicenseKey, !playerLicenseKey.isEmpty {
                vlPlayer = VLPlayer(playerType: .bitmovin(config: VLBitmovinConfig(license: VLBitmovinConfig.VLBitmovinLicenseConfig(playerKey: playerLicenseKey, analyticsKey: analyticsLicenseKey), userId: userId)))
            }else{
                vlPlayer = VLPlayer.init()
            }
            //  videoPlayerControlsView?.videoPlayer = vlPlayer
            //vlPlayer.videoPlayerDelegate = self
            //vlPlayer.clientSideAdTrackingDelegate = self
            //vlPlayer.enablePlayerBitrateLogs = self.enableBitrateLogs
            vlPlayer.setSource(type: .directStream(VLPlayer.DirectStreamPlaybackConfig(stream: VLPlayer.DirectStreamType(url: streamUrl ?? "", contentId: nil, drmconfig: drmConfig), token: vlToken, apiBaseURL: vlBaseUrl)),customControlsView: videoPlayerControlsView, playerFeaturesSupported: featureSupported) { [weak self] isSuccess, playerView, contentResponse in
                DispatchQueue.main.async {
                    if let playerView = playerView {
                        self?.addPlayerViewToContainer(playerView)
                    }
                }
            }
            
        }else{
            vlPlayer = VLPlayer(playerType: .default)
            // vlPlayer.videoPlayerDelegate = self
            //vlPlayer.clientSideAdTrackingDelegate = self
            // vlPlayer.enablePlayerBitrateLogs = self.enableBitrateLogs
            // videoPlayerControlsView?.videoPlayer = vlPlayer
            if let entitlementData{
                vlPlayer.setEntitlement(data: entitlementData)
            }
            vlPlayer.setSource(type: .contentPlayback(VLPlayer.ContentPlaybackConfig(videoId: self.videoList.videoId, token: vlToken, apiBaseURL: vlBaseUrl)),customControlsView: videoPlayerControlsView, playerFeaturesSupported: featureSupported) { [weak self] isSuccess, playerView, contentResponse in
                DispatchQueue.main.async {
                    if let playerView = playerView {
                        self?.addPlayerViewToContainer(playerView)
                        
                    }
                }
            }
        }
        
    }
    
    func addPlayerViewToContainer(_ playerView: UIView) {
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerContainerView.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: playerContainerView.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor)
        ])
    }
    private func getPlayerFeaturesSupported() -> VLPlayer.VLPlayerFeatureSupported {
        
        return VLPlayer.VLPlayerFeatureSupported(fullScreenOnly: true,
                                                 isCustomLoaderAdded: false,
                                                 shouldStartPictureInPictureInline: true,
                                                 autoPlayEnabled: true,
                                                 loopVideoPlayback: true,
                                                 hideVideoControls: false,
                                                 mutePlayback: false,
                                                 customPlayerControlsColor: nil,
                                                 clientSideAdTrackingDetails: VLPlayer.VLClientSideAdTrackingDetails.init(isClientSideAdTrackingEnabled: true, isWTAEnabled: true), showPlayerControlAlways: false,
                                                 supportsChromeCast: true,
                                                 chromecastCustomReceiver: nil,
                                                 playerResponseRequired:true,
                                                 preGameStartTime: nil,
                                                 appMacrosList: nil, vlBeacon: VLBeacon.getInstance())
    }
    
}
