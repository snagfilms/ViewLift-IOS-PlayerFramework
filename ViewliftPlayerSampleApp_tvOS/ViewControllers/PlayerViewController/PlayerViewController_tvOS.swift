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
#if os(iOS)
import VLAuthenticationFramework
#else
import VLAuthenticationFramework_tvOS
#endif
import AVKit
import VLAnalyticsLib

// Main player view controller for tvOS, handles player setup, UI, and playback logic
class PlayerViewController_tvOS: UIViewController {
    enum Configuration{
        case `default`
        case customTheme
        case custom
        #if os(tvOS)
        case native
        #endif
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
    weak var player: AVPlayer?
    var currentAdAssetInfo: VLAdAssetInfo?
    var videoResponse: VLVideoResponseModel?
    var enableCustomAdUI: Bool = false
    var analyticsAdDictionary = AnalyticsAdDictionary()
    var autoPlayListdataManager: AutoPlayDataManager?
    internal var autoPlayView: AutoPlayView?

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
        self.createAutoPlayMetaData()
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
        // Set delegates for player events and analytics
        vlPlayer?.videoPlayerDelegate = self
        
        // Set delegates for SSAID events
        vlPlayer?.serverSideAdTrackingDelegate = self
        
        vlPlayer?.playerVideoAnalyticsDelegate = self
        // Set entitlement if available
        if let entitlementData{
            vlPlayer?.setEntitlement(data: entitlementData)
        }
        // Set player source and handle completion
        
        vlPlayer?.setSource(type: playbackSourceType,
                            vlPlayerTag: "1", customControlsView: nil,adUrl: nil,
                            playerFeaturesSupported: featureSupported, nextPlaybackList: self.autoPlayListdataManager?.getAutoPlayUrlList()
                        ) { [weak self] isSuccess, playerView, contentResponse in
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
    
    // Handles player setup completion, checks for TVE authorization
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
    
    // Checks TVE authorization for the user
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
    
    // Handles TVE authorization failure
    private func handleAuthzFailure(_ error: VLAuthenticationErrorCode) {
        self.showAlert(title: "Error", message: "TVE Authorization denied")
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
                                                 controlsVisibility: .auto,
                                                 payWallConfiguration: getPayWallConfiguration(type: .default),
                                                 playerControlsViewConfiguration: getPlayerControlsViewConfiguration(type: .default),
                                                 autoPlayConfiguration: getAutoPlayConfig(type: .custom),
                                                 isTrickPlayEnabled: true,
                                                 isServerSideAdTrackingEnabled: true)
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
        #if os(tvOS)
        case .native:
            let playerControlsViewConfiguration: VLPlayer.PlayerControlsViewConfiguration = .native
            return playerControlsViewConfiguration
        #endif
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
        #if os(tvOS)
        case .native:
            return nil
        #endif
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
    
    //get trick play image data
    func getTrickPlayData(_ value: Double) -> (image: UIImage?, time: String?) {
        self.vlPlayer?.getTrickPlayData(value) ?? (nil, nil)
    }
}
