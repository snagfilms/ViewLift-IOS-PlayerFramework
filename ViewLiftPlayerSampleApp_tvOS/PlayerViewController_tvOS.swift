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
import VLAuthenticationFramework_tvOS

class PlayerViewController: UIViewController {
    
    private let playerContainerView = UIView()
    var streamUrl: String?
    var videoId: String?
    var entitlementData: VLPlayer.EntitlementData?
    var drmConfig: VLPlayer.DRMConfig?
    var streamConfig: VLPlayer.StreamConfig?
    var videoList: VideoList!
    var playerOptionSelected:PlayerUIOptions!
    var vlPlayer: VLPlayer?
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
        self.loadPlayerView()
    }
    
    func loadPlayerView() {
        let featureSupported = getPlayerFeaturesSupported()
        let vlBaseUrl = self.videoList.apiBaseUrl
        let vlBeaconURL: String? = self.videoList.beaconBaseUrl
        let vlToken = AppDelegate.shared.authorizationToken ?? ""
        
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
        vlPlayer?.videoPlayerDelegate = self
        //vlPlayer.clientSideAdTrackingDelegate = self
        // vlPlayer.enablePlayerBitrateLogs = self.enableBitrateLogs
        if let entitlementData{
            vlPlayer?.setEntitlement(data: entitlementData)
        }
        vlPlayer?.setSource(type: playbackSourceType, playerFeaturesSupported: featureSupported) { [weak self] isSuccess, playerView, contentResponse in
            DispatchQueue.main.async {
                var hasTVE = false
                
                if let video = contentResponse?["video"] as? [String: Any],
                   let monetizationModels = video["monetizationModels"] as? [[String: Any]] {
                    hasTVE = monetizationModels.contains { $0["type"] as? String == "TVE" }
                }
                
                self?.handlePlayerSetupCompletion(playerView: playerView, hasTVE: hasTVE)
                
            }
        }
    }
    
    private func handlePlayerSetupCompletion(
        playerView: UIView?,
        hasTVE: Bool
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let playerView = playerView else { return }
            
            guard let user = UserManager.shared.userIdentity else {
                self.addPlayerViewToContainer(playerView)
                return
            }
            
            if user.tveUserId != nil && hasTVE {
                self.checkAuthz(
                    user: user,
                    playerView: playerView
                )
            } else {
                self.addPlayerViewToContainer(playerView)
            }
        }
    }
    
    private func checkAuthz(user: VLUserIdentity, playerView: UIView){
        let mvpdProvider = user.mvpdProvider ?? ""
        
        VLAuthentication.sharedInstance.checkAuthz(mvpdId: mvpdProvider) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.addPlayerViewToContainer(playerView)
                case .failure(let error):
                    self.handleAuthzFailure(error)
                }
            }
        }
    }
    
    // Extract error handling for reuse/centralization
    private func handleAuthzFailure(_ error: VLAuthenticationErrorCode) {
        self.showAlert(title: "Error", message: "TVE Authorization denied")
    }
    
    private func showAlert(title: String, message: String, buttonTitle: String = "OK", completion: (() -> Void)? = nil) {
            // Create the Alert Controller
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

            // Create the action for the button.
            // The handler will execute the completion block if one was provided.
            let alertAction = UIAlertAction(title: buttonTitle, style: .default) { _ in
                completion?()
            }

            // Add the action to the alert controller
            alertController.addAction(alertAction)

            // Present the alert controller
            // Ensure this is run on the main thread, especially if called from a background task.
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
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
        /*
        // use below code configuring Default Player Controls View
        var playerControlsViewConfiguration: VLPlayer.PlayerControlsViewConfiguration?
        let style = VLPlayer.PlayerControlsViewStyle(sliderColor: .red, sliderProgressColor: .yellow)
        let textContent = VLPlayer.PlayerControlsViewTextContent(slowmoText: "SLOWMO", liveText: "LIVE", startFromBeginningText: "START FROM BEGINNING", closeCaptionHeaderText: "CLOSE CAPTION", closeCaptionText: "CLOSE CAPTION", settingHeaderText: "SETTIING", settingText: "PLAYBACK QUALITY")
        let controlsTheme = VLPlayer.PlayerControlsViewThemeConfiguration(style: style, textContent: textContent)
        if enableCustomPlayerUI{
            // use this for Custom View
            let view = VLCustomPlayerControlsView(frame: .zero, config: nil)
            view.updateTitleLabel(text: nil)
            view.delegate = self
         playerControlsViewConfiguration = .custom(view: view)
            self.videoPlayerControlsView = view
        }else{
         playerControlsViewConfiguration = .default(controlsTheme: controlsTheme)
        }
        */
        let customMacros  = ["VIEWLIFT_USER": "user_1234", "VIEWLIFT_CONTENT_TITLE": "VIDEO-TITLE"]
        // You can find list of macros in VLPlayer documentation for SSAI functioning
        //https://developer.viewlift.com/docs/vlplayerfeaturesupported
        return VLPlayer.VLPlayerFeatureSupported(appMacrosList: customMacros,
                                                 isCustomLoaderAdded: false,
                                                 shouldStartPictureInPictureInline: true,
                                                 autoPlayEnabled: self.autoplayEnabled,
                                                 loopVideoPlayback: self.loopEnabled,
                                                 hideVideoControls: self.hideControls,
                                                 mutePlayback: self.muteEnabled,
                                                 customPlayerControlsColor: nil,
                                                 showPlayerControlAlways: false,
                                                 supportsChromeCast: true,
                                                 chromecastCustomReceiver: nil,
                                                 payWallConfiguration: nil,
                                                 playerControlsViewConfiguration: nil)
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
        vlPlayer?.destroy()
        removeController()
    }
}

extension PlayerViewController: PlayerControlsDelegate {
    func setPlaybackRate(playbackSpeed: Float) {
        vlPlayer?.setPlaybackRate(playbackSpeed: playbackSpeed)
    }
    
    func getStartOverTime() -> Double? {
        vlPlayer?.getStartOverTime()
    }
    
    func isLiveVideo() -> Bool {
        vlPlayer?.isLiveVideo() ?? false
    }
    
    func isDVREnabled() -> Bool {
        vlPlayer?.isDVREnabled() ?? false
    }
    
    func getAllClosedCaptionList() -> [String]? {
        return vlPlayer?.getAllClosedCaptionList()
    }
    
    func getAllContentAudioLanguageList() -> [String]? {
        return vlPlayer?.getAllContentAudioLanguageList()
    }
    
    func getAllVideoPlaybackQualityList() -> [String]? {
        return vlPlayer?.getAllVideoPlaybackQualityList()
    }
    
    func setClosedCaption(selectedKey: String, selectedIndex: Int) {
        vlPlayer?.setClosedCaption(selectedKey: selectedKey, selectedIndex: selectedIndex)
    }
    
 
    
    func setAudioSelected(selectedAudio: String) {
        vlPlayer?.setAudioSelected(selectedAudio: selectedAudio)
    }
    
    func setCCFontSize() {
        vlPlayer?.setCCFontSize()
    }
    
    func setPlaybackQuality(playbackQuality: String) {
        vlPlayer?.setPlaybackQuality(playbackQuality: playbackQuality)
    }
    
    func getCurrentVideoDuration() -> Double? {
        self.vlPlayer?.getCurrentVideoDuration()
    }
    
    func didRequestRestart() {
        self.vlPlayer?.seekTo(seconds: 0)
        DispatchQueue.main.async {
            self.videoPlayerControlsView?.playPause(isPlaying: true)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
            self.vlPlayer?.play()
        }
    }
    
    func didTogglePlayPause() {
        
    }
    
    func seekTo(seconds: Double) {
        self.vlPlayer?.seekTo(seconds: seconds)
    }
    
    func seekToLivePosition() {
        self.vlPlayer?.seekToLivePosition()
    }
    
    
}

extension PlayerViewController: videoPlaybackDelegate {
    
    func videoFetchError(error: VLError?, playerTag: String?, contentResponse: Dictionary<String, AnyObject>?) {
        let errorDescription =  "Is content playable - \(error?.isPlayable ?? false) \n" +
        "Content Fetched successfully - \(error?.isSuccess ?? false) \n" +
        "Error Code - \(error?.errorCode ?? "errorCode") \n" +
        "Error Message - \(error?.errorMessage ?? "errorMessage") \n" +
        "Error VL Code - \(error?.vl_errorCode ?? "errorVLCode")"
        
        print("Error VL:", errorDescription)
        print("VideoFetchError: contentResponse:", contentResponse)
//        DispatchQueue.main.async {
//            self.showAlert(message: errorDescription)
//            self.customPaywallView?.update(error?.errorMessage ?? "Error occurred while fetching content")
//        }
    }
    
    func loginWithTVE() {
        debugPrint("Login with TVE called")
        VLAuthentication.sharedInstance
            .showTVEActivationScreen(
                presentingViewController: self,
                activationURL: "http://spinco.staging.web.viewlift.com/tveactivate",
                qrToggle: true) { [weak self] userIdentity, errorCode in
                    DispatchQueue.main.async {
                        if userIdentity == nil, let codeString = errorCode?.codeString {
//                            self?.showAlert(message: codeString)
                            return
                        }
                        
                        UserManager.shared.userIdentity = userIdentity
                        AppDelegate.shared.authorizationToken = userIdentity?.authorizationToken
                        self?.vlPlayer?.destroy()
                        self?.vlPlayer?.playerAdsAnalyticsDelegate = nil
                        self?.vlPlayer?.playerVideoAnalyticsDelegate = nil
                        self?.loadPlayerView()
//                        self?.logoutButton.isHidden = false
                    }
                }
        //showTVEActivationScreen
    }
    
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



