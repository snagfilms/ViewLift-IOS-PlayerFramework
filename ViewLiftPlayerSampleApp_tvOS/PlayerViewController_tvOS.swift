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
    var streamConfig: VLPlayer.StreamConfig?
    var videoList: VideoList!
    var playerOptionSelected:PlayerUIOptions!
    var vlPlayer: VLPlayer!
    var enableCustomPlayerUI:Bool = false
    var loopEnabled: Bool = false
    var autoplayEnabled: Bool = true
    var hideControls: Bool = false
    var muteEnabled: Bool = false
    var isGuestUser: Bool = false
    var videoPlayerControlsView: VLCustomPlayerControlsView?
    var portraitConstraints: [NSLayoutConstraint] = []
    var landscapeConstraints: [NSLayoutConstraint] = []
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        playerContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerContainerView)
        setupConstraints()
        updateConstraintsForCurrentOrientation()
        let featureSupported = getPlayerFeaturesSupported()
        let vlBaseUrl = self.videoList.apiBaseUrl
        let vlBeaconURL: String? = self.videoList.beaconBaseUrl
        let vlToken = self.videoList.vlToken
        
        let playerLicenseKey: String? = ""
        let analyticsLicenseKey: String? = ""
        let userId: String? = nil
        if let playerLicenseKey = playerLicenseKey, !playerLicenseKey.isEmpty {
            vlPlayer = VLPlayer(playerType: .bitmovin(config: VLBitmovinConfig(license: VLBitmovinConfig.VLBitmovinLicenseConfig(playerKey: playerLicenseKey, analyticsKey: analyticsLicenseKey), userId: userId)))
        }else{
            vlPlayer = VLPlayer(playerType: .default)
        }
        let playbackSourceType: VLPlayer.PlaybackSourceType
        if playerOptionSelected == .playStreamURL || playerOptionSelected == .playASATURL{
            playbackSourceType = .directStream(VLPlayer.DirectStreamPlaybackConfig(stream: VLPlayer.DirectStreamType(url: streamUrl ?? "", contentId: nil, streamConfig: self.streamConfig, drmconfig: drmConfig), token: vlToken, apiBaseURL: vlBaseUrl))
        }else{
            playbackSourceType = .contentPlayback(VLPlayer.ContentPlaybackConfig(videoId: self.videoList.videoId, token: vlToken, apiBaseURL: vlBaseUrl))
        }
        vlPlayer.videoPlayerDelegate = self
        //vlPlayer.clientSideAdTrackingDelegate = self
        // vlPlayer.enablePlayerBitrateLogs = self.enableBitrateLogs
        if let entitlementData{
            vlPlayer.setEntitlement(data: entitlementData)
        }
        vlPlayer.setSource(type: playbackSourceType, playerFeaturesSupported: featureSupported) { [weak self] isSuccess, playerView, contentResponse in
            DispatchQueue.main.async {
                if let playerView = playerView {
                    self?.addPlayerViewToContainer(playerView)
                    
                }
            }
        }
    }
    
   #if os(iOS)

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.updateConstraintsForCurrentOrientation()
            self.vlPlayer.goFullScreen()
        }, completion: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        vlPlayer.destroy()
    }
    #endif
    
    func updateConstraintsForCurrentOrientation() {
        let isLandscape = view.bounds.width > view.bounds.height

        NSLayoutConstraint.deactivate(portraitConstraints + landscapeConstraints)

        if isLandscape {
            NSLayoutConstraint.activate(landscapeConstraints)
        } else {
            NSLayoutConstraint.activate(portraitConstraints)
        }
    }
    
    func setupConstraints() {
        // Portrait: 16:9, top-aligned
        portraitConstraints = [
            playerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerContainerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 9.0 / 16.0)
        ]

        // Landscape: full screen
        landscapeConstraints = [
            playerContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
    }
    
    func addPlayerViewToContainer(_ playerView: UIView) {
        playerContainerView.addSubview(playerView)
        playerContainerView.backgroundColor = .white
        //playerView.frame = CGRect.init(x: 0, y: 0, width: view.bounds.width , height: (view.bounds.width) * 9/16)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: playerContainerView.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor)
        ])
    }
    private func getPlayerFeaturesSupported() -> VLPlayer.VLPlayerFeatureSupported {
        var config: VLPlayer.PlayerControlsViewConfiguration?
        if enableCustomPlayerUI{
            let view = VLCustomPlayerControlsView(frame: .zero, config: nil)
            view.updateTitleLabel(text: nil)
            view.delegate = self
            config = .custom(view: view)
            self.videoPlayerControlsView = view
        }

        return VLPlayer.VLPlayerFeatureSupported(fullScreenOnly: true,
                                                 isCustomLoaderAdded: false,
                                                 shouldStartPictureInPictureInline: true,
                                                 autoPlayEnabled: autoplayEnabled,
                                                 loopVideoPlayback: loopEnabled,
                                                 hideVideoControls: hideControls,
                                                 mutePlayback: muteEnabled,
                                                 customPlayerControlsColor: nil,
                                                 clientSideAdTrackingDetails: VLPlayer.VLClientSideAdTrackingDetails.init(isClientSideAdTrackingEnabled: true, isWTAEnabled: true), showPlayerControlAlways: false,
                                                 supportsChromeCast: true,
                                                 chromecastCustomReceiver: nil,
                                                 playerResponseRequired:true,
                                                 preGameStartTime: nil,
                                                 appMacrosList: nil, vlBeacon: VLBeacon.getInstance(), payWallConfiguration: nil, playerControlsViewConfiguration: config)
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) {
            print("CustomVideoController Menu button pressed – handle custom back")
            self.menuPressed()
            return
        }
        super.pressesBegan(presses, with: event)
    }
    
    func removeController(){
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
            
        }
    }
    
    func menuPressed() {
        vlPlayer.destroy()
        removeController()
    }
}

extension PlayerViewController: PlayerControlsDelegate {
    func setPlaybackRate(playbackSpeed: Float) {
        vlPlayer.setPlaybackRate(playbackSpeed: playbackSpeed)
    }
    
    func getStartOverTime() -> Double? {
        vlPlayer.getStartOverTime()
    }
    
    func isLiveVideo() -> Bool {
        vlPlayer.isLiveVideo()
    }
    
    func isDVREnabled() -> Bool {
        vlPlayer.isDVREnabled() ?? false
    }
    
    func getAllClosedCaptionList() -> [String]? {
        return vlPlayer.getAllClosedCaptionList()
    }
    
    func getAllContentAudioLanguageList() -> [String]? {
        return vlPlayer.getAllContentAudioLanguageList()
    }
    
    func getAllVideoPlaybackQualityList() -> [String]? {
        return vlPlayer.getAllVideoPlaybackQualityList()
    }
    
    func setClosedCaption(selectedKey: String, selectedIndex: Int) {
        vlPlayer.setClosedCaption(selectedKey: selectedKey, selectedIndex: selectedIndex)
    }
    
 
    
    func setAudioSelected(selectedAudio: String) {
        vlPlayer.setAudioSelected(selectedAudio: selectedAudio)
    }
    
    func setCCFontSize() {
        vlPlayer.setCCFontSize()
    }
    
    func setPlaybackQuality(playbackQuality: String) {
        vlPlayer.setPlaybackQuality(playbackQuality: playbackQuality)
    }
    
    func getCurrentVideoDuration() -> Double? {
        self.vlPlayer.getCurrentVideoDuration()
    }
    
    func didRequestRestart() {
        self.vlPlayer.seekTo(seconds: 0)
        DispatchQueue.main.async {
            self.videoPlayerControlsView?.playPause(isPlaying: true)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
            self.vlPlayer.play()
        }
    }
    
    func didTogglePlayPause() {
        
    }
    
    func seekTo(seconds: Double) {
        self.vlPlayer.seekTo(seconds: seconds)
    }
    
    func seekToLivePosition() {
        self.vlPlayer.seekToLivePosition()
    }
    
    
}

extension PlayerViewController: videoPlaybackDelegate {
    
    func customPlayerState(isPlaying: Bool) {
        videoPlayerControlsView?.playPause(isPlaying: isPlaying)
    }
    
    func isSubtitlesEmbeddedInUrlChanged(isEmbedded: Bool) {
        debugPrint("PlayerViewController isSubtitlesEmbeddedInUrlChanged: \(isEmbedded)")
    }
    
    func didFinishPlaying() {
        print("PlayerViewController didFinishPlaying")
    }
    
    func customPlayerControls(isHidden: Bool) {
        print("PlayerViewController customPlayerControls: \(isHidden)")
        if isHidden{
            videoPlayerControlsView?.customPlayerControls(isHidden: isHidden)
        }
    }
    
    func videoStarted(timestamp: Double, playerTag: String) {
//        videoPlayerControlsView?.setPlayButtonState(state: true)
//        videoPlayerControlsView?.updateTimeLabelOnStart()
//        videoPlayerControlsView?.playPauseImageView
        videoPlayerControlsView?.videoStartedPlaying(timestamp: timestamp)
        debugPrint("PlayerViewController videoStarted: \(timestamp)")
    }
    
    func videoPlayerProgressByEverySecond(currentTime: Double, totalTime: Double, playerTag: String, parsedTimeStamp: String?) {
        debugPrint("PlayerViewController videoPlayerProgre]ssByEverySecond: \(currentTime), \(totalTime)")
        videoPlayerControlsView?.updateCurrentTime(currentTime: currentTime, totalTime: totalTime)

    }
    
    func videoPlayerUpdateByProgressInterveral(currentTime: Double, totalTime: Double, playerTag: String) {
        debugPrint("PlayerViewController videoPlayerProgre]ssByEverySecond: \(currentTime), \(totalTime)")

        videoPlayerControlsView?.updateCurrentTime(currentTime: currentTime, totalTime: totalTime)

    }
    
    func onBackButtonTapped() {
        menuPressed()
    }
}

extension UIView {
    func parentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let vc = next as? UIViewController {
                return vc
            }
            responder = next
        }
        return nil
    }
}



