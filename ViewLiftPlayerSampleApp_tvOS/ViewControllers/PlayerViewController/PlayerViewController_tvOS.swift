//
//  PlayerViewController_tvOS.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 17/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit
import VLPlayerLib

// Main player view controller for tvOS, handles player setup, UI, and playback logic
class PlayerViewController_tvOS: UIViewController {
    enum Configuration{
        case `default`
        case customTheme
        case custom
    }
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
    var customPaywallView: CustomPaywallView?
    var portraitConstraints: [NSLayoutConstraint] = []
    var landscapeConstraints: [NSLayoutConstraint] = []
    var enableCustomAdUI: Bool = false
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // Initial setup for the view and player
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        playerContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerContainerView)
        setupConstraints()
        updateConstraintsForCurrentOrientation()
        self.loadPlayerView()
    }
    
    // Loads and configures the player view
    func loadPlayerView() {
        let featureSupported = getPlayerFeaturesSupported()
        let vlBaseUrl = self.videoList.apiBaseUrl
        let vlBeaconURL: String? = self.videoList.beaconBaseUrl
        let vlToken = AppDelegate.shared.authorizationToken ?? ""
        
        let playerLicenseKey: String? = ""
        let analyticsLicenseKey: String? = ""
        let userId: String? = nil
        // Initialize player with license if available
        if let playerLicenseKey = playerLicenseKey, !playerLicenseKey.isEmpty {
            vlPlayer = VLPlayer(playerType: .bitmovin(config: VLBitmovinConfig(license: VLBitmovinConfig.VLBitmovinLicenseConfig(playerKey: playerLicenseKey, analyticsKey: analyticsLicenseKey), userId: userId)))
        }else{
            vlPlayer = VLPlayer(playerType: .default)
        }
        // Select playback source type based on user option
        let playbackSourceType: VLPlayer.PlaybackSourceType
        if playerOptionSelected == .playStreamURL || playerOptionSelected == .playASATURL{
            playbackSourceType = .directStream(VLPlayer.DirectStreamPlaybackConfig(stream: VLPlayer.DirectStreamType(url: streamUrl ?? "", streamConfig: self.streamConfig, drmconfig: drmConfig), token: vlToken, apiBaseURL: vlBaseUrl))
        }else{
            playbackSourceType = .contentPlayback(VLPlayer.ContentPlaybackConfig(videoId: self.videoList.videoId, token: vlToken, apiBaseURL: vlBaseUrl))
        }
        // Set delegates for player events
        vlPlayer?.videoPlayerDelegate = self
        // Set entitlement if available
        if let entitlementData{
            vlPlayer?.setEntitlement(data: entitlementData)
        }
        // Set player source and handle completion
        vlPlayer?.setSource(type: playbackSourceType, playerFeaturesSupported: featureSupported) { [weak self] isSuccess, playerView, contentResponse in
            DispatchQueue.main.async {
                self?.handlePlayerSetupCompletion(playerView: playerView)
                
            }
        }
    }
    
    // Handles player setup completion, checks for TVE authorization
    private func handlePlayerSetupCompletion(
        playerView: UIView?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let playerView = playerView else { return }
            
            
            self.addPlayerViewToContainer(playerView)
        }
    }
        
    // Shows an alert with a title and message
    private func showAlert(title: String, message: String, buttonTitle: String = "OK", completion: (() -> Void)? = nil) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: buttonTitle, style: .default) { _ in
                completion?()
            }
            alertController.addAction(alertAction)
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
    }
    
   #if os(iOS)
    // Handles orientation changes
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
    
    // Updates constraints based on current orientation
    func updateConstraintsForCurrentOrientation() {
        let isLandscape = view.bounds.width > view.bounds.height

        NSLayoutConstraint.deactivate(portraitConstraints + landscapeConstraints)

        if isLandscape {
            NSLayoutConstraint.activate(landscapeConstraints)
        } else {
            NSLayoutConstraint.activate(portraitConstraints)
        }
    }
    
    // Sets up portrait and landscape constraints for the player container
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
    
    // Adds the player view to the container and sets constraints
    func addPlayerViewToContainer(_ playerView: UIView) {
        playerContainerView.addSubview(playerView)
        playerContainerView.backgroundColor = .white
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: playerContainerView.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor)
        ])
    }

    // Returns player features supported configuration
    private func getPlayerFeaturesSupported() -> VLPlayer.VLPlayerFeatureSupported {
        let customMacros  = ["VIEWLIFT_USER": "user_1234", "VIEWLIFT_CONTENT_TITLE": "VIDEO-TITLE"]
        // See VLPlayer documentation for available macros
        return VLPlayer.VLPlayerFeatureSupported(appMacrosList: customMacros,
                                                 isCustomLoaderAdded: false,
                                                 shouldStartPictureInPictureInline: true,
                                                 loopVideoPlayback: self.loopEnabled,
                                                 mutePlayback: self.muteEnabled,
                                                 customPlayerControlsColor: nil,
                                                 supportsChromeCast: true,
                                                 chromecastCustomReceiver: nil,
                                                 payWallConfiguration: getPayWallConfiguration(type: .default),
                                                 playerControlsViewConfiguration: getPlayerControlsViewConfiguration(type: .default))
    }
    
    // Returns player controls view configuration based on type
    private func getPlayerControlsViewConfiguration(type: Configuration) -> VLPlayer.PlayerControlsViewConfiguration? {
        switch type {
        case .customTheme:
            // Configure default player controls view with custom theme
            let style = VLPlayer.PlayerControlsViewStyle(sliderColor: .red, sliderProgressColor: .yellow)
            let textContent = VLPlayer.PlayerControlsViewTextContent(slowmoText: "SLOWMO", liveText: "LIVE", startFromBeginningText: "START FROM BEGINNING", closeCaptionHeaderText: "CLOSE CAPTION", closeCaptionText: "CLOSE CAPTION", settingHeaderText: "SETTIING", settingText: "PLAYBACK QUALITY")
            let controlsTheme = VLPlayer.PlayerControlsViewThemeConfiguration(style: style, textContent: textContent)
            let playerControlsViewConfiguration: VLPlayer.PlayerControlsViewConfiguration = .default(controlsTheme: controlsTheme)
            return playerControlsViewConfiguration
        case .custom:
            // Use a custom controls view
            let view = VLCustomPlayerControlsView(frame: .zero, config: nil)
            view.updateTitleLabel(text: nil)
            view.delegate = self
            let playerControlsViewConfiguration: VLPlayer.PlayerControlsViewConfiguration = .custom(view: view)
            self.videoPlayerControlsView = view
            return playerControlsViewConfiguration
        case .default:
            // Use default controls view and theme
            return nil
        }
    }
    
    // Returns paywall configuration based on type
    private func getPayWallConfiguration(type: Configuration) -> VLPlayer.PayWallConfiguration?{
        switch type {
        case .customTheme:
            // Configure default paywall view with custom theme
            let payWallStyle = VLPlayer.PayWallStyle(errorMessageTextColor: .red, buttonTextColor: .blue, buttonBackgroundColor: .yellow, backgroundColor: nil)
            let payWallTextContent = VLPlayer.PayWallTextContent(errorMessage: "Error", buttontext: nil)
            let payWallThemeConfiguration = VLPlayer.PayWallThemeConfiguration(style: payWallStyle, textContent: payWallTextContent)
            let payWallConfiguration: VLPlayer.PayWallConfiguration = VLPlayer.PayWallConfiguration.default(payWallTheme: payWallThemeConfiguration)
            return payWallConfiguration
        case .custom:
            // Use a custom paywall view
            let customPaywallView = CustomPaywallView()
            let payWallConfiguration: VLPlayer.PayWallConfiguration = .custom(view: customPaywallView)
            self.customPaywallView = customPaywallView
            return payWallConfiguration
        case .default:
            // Use default paywall view and theme
            return nil
        }
    }
    
    // Handles remote control presses (menu button)
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) {
            print("CustomVideoController Menu button pressed – handle custom back")
            self.menuPressed()
            return
        }
        super.pressesBegan(presses, with: event)
    }
    
    // Removes the controller from navigation stack or dismisses it
    func removeController(){
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // Handles menu button press to destroy player and remove controller
    func menuPressed() {
        vlPlayer?.destroy()
        removeController()
    }
    
    // Shows a simple alert with a message
    func showAlert(title: String = "Alert!", message: String = "Description") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

// Delegate for player controls actions
extension PlayerViewController_tvOS: PlayerControlsDelegate {
    // Sets playback rate for the player
    func setPlaybackRate(playbackSpeed: Float) {
        vlPlayer?.setPlaybackRate(playbackSpeed: playbackSpeed)
    }
    
    // Returns start over time if available
    func getStartOverTime() -> Double? {
        vlPlayer?.getStartOverTime()
    }
    
    // Checks if the current video is live
    func isLiveVideo() -> Bool {
        vlPlayer?.isLiveVideo() ?? false
    }
    
    // Checks if DVR is enabled
    func isDVREnabled() -> Bool {
        vlPlayer?.isDVREnabled() ?? false
    }
    
    // Returns all closed caption options
    func getAllClosedCaptionList() -> [String]? {
        return vlPlayer?.getAllClosedCaptionList()
    }
    
    // Returns all available audio languages
    func getAllContentAudioLanguageList() -> [String]? {
        return vlPlayer?.getAllContentAudioLanguageList()
    }
    
    // Returns all available playback quality options
    func getAllVideoPlaybackQualityList() -> [String]? {
        return vlPlayer?.getAllVideoPlaybackQualityList()
    }
    
    // Sets the selected closed caption
    func setClosedCaption(selectedKey: String, selectedIndex: Int) {
        vlPlayer?.setClosedCaption(selectedKey: selectedKey, selectedIndex: selectedIndex)
    }
    
    // Sets the selected audio language
    func setAudioSelected(selectedAudio: String) {
        vlPlayer?.setAudioSelected(selectedAudio: selectedAudio)
    }
    
    // Sets closed caption font size
    func setCCFontSize() {
        vlPlayer?.setCCFontSize()
    }
    
    // Sets the selected playback quality
    func setPlaybackQuality(playbackQuality: String) {
        vlPlayer?.setPlaybackQuality(playbackQuality: playbackQuality)
    }
    
    // Returns the current video duration
    func getCurrentVideoDuration() -> Double? {
        self.vlPlayer?.getCurrentVideoDuration()
    }
    
    // Handles restart request from controls
    func didRequestRestart() {
        self.vlPlayer?.seekTo(seconds: 0)
        DispatchQueue.main.async {
            self.videoPlayerControlsView?.playPause(isPlaying: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
            self.vlPlayer?.play()
        }
    }
    
    // Handles play/pause toggle
    func didTogglePlayPause() {
        
    }
    
    // Seeks to a specific time in the video
    func seekTo(seconds: Double) {
        self.vlPlayer?.seekTo(seconds: seconds)
    }
    
    // Seeks to the live position in the stream
    func seekToLivePosition() {
        self.vlPlayer?.seekToLivePosition()
    }
}
