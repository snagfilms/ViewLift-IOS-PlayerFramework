//
//  PlayerViewController_iOS.swift
//  ViewliftPlayerSampleApp
//
//  Created by Gaurav Vig on 16/11/21.
//  Copyright © 2021 Viewlift. All rights reserved.
//

import UIKit
import VLPlayerLib
import VLBeaconLib
#if os(iOS)
import VLAuthenticationFramework
#else
import VLAuthenticationFramework_tvOS
#endif
import VLAnalyticsLib
import Foundation
import AVKit

// MARK: - Constants
/// Contains static constants used for player layout and configuration
private enum Constants {
    static let playerMargin: CGFloat = 10
    static let aspectRatio: CGFloat = 9/16
    static let defaultSeekForward: Double = 30.0
    static let defaultSeekBackward: Double = 10.0
    static let playerYPosition: CGFloat = 100
    static let defaultAdUrl = "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/simid&description_url=https%3A%2F%2Fdevelopers.google.com%2Finteractive-media-ads&sz=640x480&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&correlator="
}

/// Main view controller for player screen on iOS
class PlayerViewController_iOS: UIViewController {
    /// Player configuration options
    enum Configuration{
        case `default`
        case customTheme
        case custom
        case disabled
        case native
    }
    // MARK: - IBOutlets
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet var debugLogView: UITextView!
    @IBOutlet private weak var addNextButton: UIButton!
    @IBOutlet private weak var playNextButton: UIButton!
    @IBOutlet private weak var backButton: UIButton!
    // MARK: - Properties
    var customPaywallView: CustomPaywallView?
    private var videoList: VideoList!
    var vlPlayer: VLPlayer?
    var videoPlayerControlsView: CustomVideoControls? // using UIKIT
    var videoPlayerCustomView: (view: UIView?, viewModel: PlayerControlsViewModel?)? // using SwiftUI
    
    // Configuration Properties
    var enableCustomPlayerUI: Bool = false
    var enableBitrateLogs: Bool = false
    var entitlementData: VLPlayer.EntitlementData?
    var drmConfig: VLPlayer.DRMConfig?
    var streamConfig: VLPlayer.StreamConfig?
    var loopEnabled: Bool = false
    var autoplayEnabled: Bool = true
    var hideControls: Bool = false
    var muteEnabled: Bool = false
    var streamUrl: String?
    var totalAdsDuration: Double = 0.0
    
    var channelId: [String] = [] {
        didSet {
            self.channelkey = self.channelId.joined(separator: ",")
        }
    }
    
    var channelkey: String = ""
    
    weak var player: AVPlayer?
    var currentAdAssetInfo: VLAdAssetInfo?
    var videoResponse: VLVideoResponseModel?
    let timerLabel = UILabel()
    let playerContainerView = UIView()
    var fullscreenConstraints: [NSLayoutConstraint] = []
    var normalConstraints: [NSLayoutConstraint] = []
    var isFullscreen = false
    var allowLandscapeRotation: Bool = true
    private var nextVideoLists: [String] = [] {
        didSet {
            updateButtonStates()
        }
    }
    private lazy var addedNextVideoList: [String] = [] {
        didSet {
            updateButtonStates()
        }
    }
    private var playableVideoId: String?
    private var seekForwardDuration: Double = Constants.defaultSeekForward
    private var seekBackwardDuration: Double = Constants.defaultSeekBackward
    private var adUrl: String?
    private var playerOptionSelected: PlayerUIOptions!
    var enableCustomAdUI: Bool = false
    var playerRateBeforeSeek: Float = 1.0
    var isVideoPlayingBeforeSeek = true
    var autoPlayListdataManager: AutoPlayDataManager?
    internal var autoPlayView: AutoPlayView?
    // MARK: - Computed Properties
    /// Calculates the frame for the player view based on screen size and constants
    var playerFrame: CGRect {
        let width = UIScreen.main.bounds.width - (Constants.playerMargin * 2)
        let height = width * Constants.aspectRatio
        return CGRect(x: Constants.playerMargin,
                      y: Constants.playerYPosition,
                      width: width,
                      height: height)
    }
    
    /// Returns the current authorization token from AppDelegate
    private var vlToken: String {
        return AppDelegate.shared.authorizationToken ?? ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VLAnalytics.shared.startObservingPlayerEvents()
        
        playerContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerContainerView)
        setupConstraints()
        setupInitialState()
        createAutoPlayMetaData()
        
        timerLabel.isHidden = true
        
        Task {
            await self.loadPlayerView()
        }
        
        self.logoutButton.isHidden = true
        
        // Show logout button if user is logged in
        if UserManager.shared.userIdentity != nil {
            self.logoutButton.isHidden = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        self.stopTempPassTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        VLAnalytics.shared.stopObservingPlayerEvents()
    }
    
    func setupConstraints() {
        
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.textColor = .white
        timerLabel.backgroundColor = .black
        timerLabel.textAlignment = .center
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        timerLabel.text = "00:00"
        
        timerLabel.isHidden = true
        
        // Add label inside playerContainerView
        playerContainerView.addSubview(timerLabel)
        // Bring label to front within playerContainerView
        playerContainerView.bringSubviewToFront(timerLabel)

        
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: playerContainerView.topAnchor, constant: 16),
            timerLabel.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor, constant: -16),
            timerLabel.heightAnchor.constraint(equalToConstant: 20),
            timerLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])

        
        normalConstraints = [
            playerContainerView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Maintain 16:9 aspect ratio
            playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 9.0/16.0)
        ]

        // Fullscreen constraints
        fullscreenConstraints = [
            playerContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        NSLayoutConstraint.activate(normalConstraints)
    }
    

    
    deinit {
        cleanupResources()
    }
    
    /// Sets up initial UI state and debug log visibility
    private func setupInitialState() {
        updateButtonStates()
        if enableBitrateLogs {
            debugLogView.isHidden = false
        }
    }
    
    private func updateButtonStates() {
        addNextButton.isEnabled = !nextVideoLists.isEmpty
        playNextButton.isEnabled = !addedNextVideoList.isEmpty
    }
    
    /// Cleans up player and UI resources
    internal func cleanupResources() {
//        self.stopTempPassTimer()
        
        vlPlayer?.destroy()
        vlPlayer?.playerVideoAnalyticsDelegate = nil
        videoPlayerControlsView?.removeFromSuperview()
        videoPlayerCustomView?.view?.removeFromSuperview()
    }
    
    /// Prepares the view with selected player UI option and video list
    func prepareView(withPlayerUIOption playerOptionSelected: PlayerUIOptions, videoList: VideoList) {
        self.videoList = videoList
        self.playerOptionSelected = playerOptionSelected
        self.playableVideoId = videoList.videoId
        
        configurePlayerOptions(playerOptionSelected)
    }
    
    /// Configures player options based on selected UI option
    private func configurePlayerOptions(_ option: PlayerUIOptions) {
        switch option {
        case .customControlWithDebugLog, .debugLogEnabled:
            enableBitrateLogs = true
        case .customControl, .customControlWithCustomSeekDuration:
            enableCustomPlayerUI = true
        case .adsEnabled:
            adUrl = Constants.defaultAdUrl
        default:
            break
        }
    }
    
    /// Handles logout button tap, logs out user and resets player
    @IBAction func logoutButtonAction(_ sender: Any) {
        self.performLogout()
    }
    
    func performLogout(isForceLogout: Bool = false) {
        let mvpdProvider = UserManager.shared.userIdentity?.mvpdProvider
        
        VLAuthentication.sharedInstance.logout(
            client: .tvProvider(provider: .adobe, tveInitializationConfig: nil),
            mvpdId: mvpdProvider
        ) { [weak self] logoutSuccessful in
            if logoutSuccessful {
                Task { [weak self] in
//                    AnalyticsHelper.shared.triggerSignoutAnalytics()
                    
                    self?.logoutButton.isHidden = true
                    
                    await AppDelegate.shared.logoutUser()
                    self?.vlPlayer?.destroy()
                    await self?.loadPlayerView()
                }
            }
            
            if isForceLogout {
                VLAuthentication.sharedInstance.clearTveAuthDetails()
            }
        }
    }
}

// MARK: - Player Setup
extension PlayerViewController_iOS {
    
    /// Loads and configures the player view
    func loadPlayerView() async {
        
        let loaderView = addLoaderView(to: playerContainerView)
        loaderView.startAnimating()

        self.timerLabel.isHidden = true
        
        if UserManager.shared.userIdentity?.tveUserId == nil && !isPlayingFromURL() {
                //check if ealier temp pass was created but not expired
                self.invalidatePlayerTempPassIfOutOfWindow()

                //request for temp pass
                await self.getTempPassPayload()
        }
        
        let featureSupported = getPlayerFeaturesSupported()
        let vlBaseUrl = videoList.apiBaseUrl
        
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
        if isPlayingFromURL(){
            let isDVREnabled = streamConfig?.isDVR ?? false
            let streamType = VLPlayer.DirectStreamType(
                url: streamUrl ?? "",
                streamConfig: streamConfig,
                drmconfig: drmConfig
            )
            
            let playbackConfig = VLPlayer.DirectStreamPlaybackConfig(
                stream: streamType
            )
            
            playbackSourceType = .directStream(playbackConfig)
            
        } else {
            let adobePassPayload = try? AppDelegate.shared.adobePlayerTempPass[self.channelkey]?.getTempToken() ?? nil
            
            playbackSourceType =
                .contentPlayback(
                    VLPlayer
                        .ContentPlaybackConfig(
                            videoId: self.videoList.videoId,
                            token: vlToken,
                            apiBaseURL: vlBaseUrl,
                            adobeTempPassPayload: adobePassPayload
                        )
                )
        }
            
            setPlayerDelegates()
            
            if let data = entitlementData {
                vlPlayer?.setEntitlement(data: data)
            }
            
//            let autoPlayList = autoPlayListdataManager?.getAutoPlayUrlList()
            
            // Set player source and handle completion
           vlPlayer?.setSource(
                type: playbackSourceType,
                vlPlayerTag: "1", customControlsView: nil,adUrl: nil,
                playerFeaturesSupported: featureSupported, nextPlaybackList: nil
            ) {
                [weak self] isSuccess,
                playerView,
                contentResponse in
                
                if let contentResponse = contentResponse {
                    self?.videoResponse = AnalyticsHelper.shared.parseVLVideoResponse(from: contentResponse)
                }
                
                var hasTVE = false
                
                // Check if content has TVE monetization model
                if let video = contentResponse?["video"] as? [String: Any],
                   let monetizationModels = video["monetizationModels"] as? [[String: Any]] {
                    hasTVE = monetizationModels.contains { $0["type"] as? String == "TVE" }
                }
                
                let plans = contentResponse?["plans"] as? [[String: Any]] ?? []
                let channelIds = plans
                    .flatMap { $0["planDetails"] as? [[String: Any]] ?? [] }
                    .flatMap { $0["channelIds"] as? [String] ?? [] }
                
                self?.handlePlayerSetupCompletion(
                    isSuccess: isSuccess,
                    playerView: playerView,
                    isDVREnabled: false,
                    loader: loaderView,
                    hasTVE: hasTVE,
                    channelIds: channelIds
                )
                
                if let video = contentResponse?["video"] as? [String: Any] {
                    let title = (video["title"] as? String) ?? ""
                    let isLive = ((video["streamingInfo"] as? [String: Any])?["isLiveStream"] as? Bool ) ?? false
                    
                    var isDVR = false
                    if let liveDetailsDict = video["liveDetails"] as? Dictionary<String, Any>{
                        if let isDVREnabled = liveDetailsDict["isDvrEnabled"] as? Bool,
                           isDVREnabled == true,
                           let startOverTime = liveDetailsDict["startOverTime"] as? Double, startOverTime > 0 {
                            isDVR = isDVREnabled
                        }
                    }
                    self?.videoPlayerCustomView?.viewModel?.updateSkin(title: title, isLive: isLive, isDVREnabled: isDVR)
                }
                
                
            }

    }
    
    private func isPlayingFromURL() -> Bool{
        return playerOptionSelected == .playStreamURL || playerOptionSelected == .playASATURL
    }
    
    /// Determines if direct stream should be used based on player option
    private func shouldUseDirectStream() -> Bool {
        return playerOptionSelected == .playStreamURL || playerOptionSelected == .playASATURL
    }

    /// Configures player delegates and settings
    private func setPlayerDelegates() {
        videoPlayerControlsView?.videoPlayer = vlPlayer
        vlPlayer?.videoPlayerDelegate = self
//        vlPlayer?.playerVideoAnalyticsDelegate = AnalyticsHelper.shared
        vlPlayer?.enablePlayerBitrateLogs = enableBitrateLogs
        vlPlayer?.serverSideAdTrackingDelegate = self
        vlPlayer?.castDelegate = self
    }
    
    /// Handles completion of player setup, including TVE checks and UI updates
    private func handlePlayerSetupCompletion(
        isSuccess: Bool,
        playerView: UIView?,
        isDVREnabled: Bool,
        loader: UIActivityIndicatorView,
        hasTVE: Bool,
        channelIds: [String]
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            loader.stopAnimating()
            
            guard let playerView = playerView else { return }
            
            // If user is not logged in, just add player
            guard let user = UserManager.shared.userIdentity else {
                if isDVREnabled {
                    self.videoPlayerControlsView?.updateControlsBasedOnDVRFlag(isDVREnabled: isDVREnabled)
                }
                self.addPlayer(playerView: playerView)
                return
            }
            
            // If user is TVE and content requires TVE, check authorization
            if user.tveUserId != nil && hasTVE {
                Task {
                    await self.checkAuthz(
                        user: user,
                        playerView: playerView,
                        isDVREnabled: isDVREnabled,
                        channelIds: channelIds
                    )
                }
            } else {
                if isDVREnabled {
                    self.videoPlayerControlsView?.updateControlsBasedOnDVRFlag(isDVREnabled: isDVREnabled)
                }
                self.addPlayer(playerView: playerView)
            }
        }
    }
    
    /// Checks TVE authorization for the user before playback
    private func checkAuthz(user: VLUserIdentity, playerView: UIView, isDVREnabled: Bool, channelIds: [String] = []) async {
        let mvpdProvider = user.mvpdProvider ?? ""
        
        do {
            let response = try await VLAuthentication.sharedInstance.checkAdobeDecisionsAuthorize(
                mvpdId: mvpdProvider,
                channelIds: channelIds
            )
            
            switch response {
            case .success(_):
                if isDVREnabled {
                    self.videoPlayerControlsView?.updateControlsBasedOnDVRFlag(isDVREnabled: isDVREnabled)
                }
                self.addPlayer(playerView: playerView)
                
            case .failure(let error):
                self.handleAuthzFailure(
                    VLAuthenticationErrorCode
                        .decodingFailed(
                            message: error.localizedDescription,
                            underlyingError: error
                        )
                )
            }
        } catch (let error as VLAuthenticationErrorCode){
            self.vlPlayer?.destroy()
            self.handleAuthzFailure(error)
        } catch {
            debugPrint(error)
        }
    }
    
    /// Handles TVE authorization failure
    private func handleAuthzFailure(_ error: VLAuthenticationErrorCode) {
        switch error {
        case .adobeErrorResponse(_, _, _, let shouldPerformLogout):
            if shouldPerformLogout {
                self.showAlert(title: "Error", message: "TVE Authorization denied"){
                    self.performLogout(isForceLogout: true)
                }
            }
            break
        default:
            self.showAlert(title: "Error", message: "TVE Authorization denied")
        }
        
    }
    
    /// Adds the player view to the main view and sets up custom UI if enabled
    func addPlayer(playerView: UIView) {
        if enableCustomPlayerUI {
            setupCustomPlayerUI()
        }
       // playerView.frame = playerFrame
        playerContainerView.addSubview(playerView)
        playerView.pinToSuperview(insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        
        playerContainerView.bringSubviewToFront(timerLabel)
    
        
        self.vlPlayer?
            .setAnalyticsInfo(
                mediaAnalyticsInfo: MediaAnalyticsInfo(
                    contentInfo: VLContentInfoAnalytics(videonetwork: "test"),
                    playerInfo: AnalyticsPlayerInfo(
                        playerVersion: "3.0.0",
                        playerName: "AVPlayer",
                        playerTech: "AVPlayer",
                        publisher: AnalyticsHelperV2.shared.orgid
                    ),
                )
            )
        
//        V1
//        if let contentInfo = self.getVideoInfo() {
//            AnalyticsHelper.shared.setVideoAssets(contentInfo: contentInfo)
//            
//            AnalyticsHelper.shared.playerDidLoadVideo()
//        }
        
        //V2
//        if let contentInfo = self.getVideoInfoV2() {
//            self.vlPlayer?
//                .setAnalyticsInfo(
//                    contentInfo: contentInfo,
//                    playerInfo: AnalyticsHelperV2.shared.getPlayerInfo(),
//                    tvProviderInfo: AnalyticsHelperV2.shared
//                        .getTVEProviderInfo()
//                )
//        }
    }
    
    /// Sets up custom player UI controls and PiP
    private func setupCustomPlayerUI() {
//        videoPlayerControlsView?.setupPictureInPicture()
//        videoPlayerControlsView?.startPictureInPictureInline(enable: true)
//        videoPlayerControlsView?.updatePlayerControlsType(playerControlType: self.vlPlayer.isLiveVideo() ? .liveVideoControls : .streamVideoControls)
        
//        vlPlayer.setupPictureInPicture()
    }
    
    /// Returns a custom controls view, optionally with custom seek durations
    private func getCustomControls() -> CustomVideoControls {
        let controlsView = CustomVideoControls(frame: playerFrame)
        
        if playerOptionSelected == .customControlWithCustomSeekDuration {
            controlsView.seekBackwardDuration = seekBackwardDuration
            controlsView.seekForwardDuration = seekForwardDuration
        }
        
        return controlsView
    }

    func getCustomPlayerSkin() -> (view: UIView?, viewModel: PlayerControlsViewModel?) {
        if self.videoPlayerCustomView?.view != nil {
            self.videoPlayerCustomView?.view?.removeFromSuperview()
            self.videoPlayerCustomView?.view = nil
            self.videoPlayerCustomView?.viewModel = nil
            self.videoPlayerCustomView = nil
        }

        let playerControlsConfig = PlayerControlsConfig(
            isChromeCastSupported: true,
            isAirPlaySupported: true,
            isPIPSupported: true,
            isSettingsSupported: true,
            isSubTitleSupported: true,
            isSlowMoSupported: true,
            isVideoLiveStream: streamConfig?.isLive ?? false,
            isDVREnabled: streamConfig?.isDVR ?? false,
            videoTitle: "",
            playerControlsColor: nil
        )

        let viewModel = PlayerControlsViewModel(delegate: self,
                                                playerControlsConfig: playerControlsConfig)

        let customView = PlayerControlsHostingView(viewModel: viewModel)
        self.videoPlayerCustomView = (view: customView, viewModel: viewModel)
        
        return self.videoPlayerCustomView!
    }

    /// Returns the supported player features configuration
    private func getPlayerFeaturesSupported() -> VLPlayer.VLPlayerFeatureSupported {
        let customMacros  = ["VIEWLIFT_USER": "user_1234", "VIEWLIFT_CONTENT_TITLE": "VIDEO-TITLE"]
        // You can find list of macros in VLPlayer documentation for SSAI functioning
        //https://developer.viewlift.com/docs/vlplayerfeaturesupported
        return VLPlayer.VLPlayerFeatureSupported(appMacrosList: nil,
                                                 isCustomLoaderAdded: false,
                                                 shouldStartPictureInPictureInline: true,
                                                 loopVideoPlayback: self.loopEnabled,
                                                 mutePlayback: self.muteEnabled,
                                                 customPlayerControlsColor: nil,
                                                 supportsChromeCast: true,
                                                 chromecastCustomReceiver: nil,
                                                 controlsVisibility: .auto,
                                                 payWallConfiguration: getPayWallConfiguration(type: .default),
                                                 autoPlayConfiguration: getAutoPlayConfig(type: .default),
                                                 isTrickPlayEnabled: false,
                                                 isCustomAdViewEnabled: enableCustomAdUI,
                                                 isServerSideAdTrackingEnabled: true)
    }
        
    /// Returns the paywall configuration based on the type
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
            // Uses default paywall view
            return .default(payWallTheme: nil)
        default :
            return .disabled
        }
    }
}

// MARK: - UI Helpers
extension PlayerViewController_iOS {
    
    /// Adds and returns a loader (activity indicator) to the given container view
    private func addLoaderView(to containerView: UIView) -> UIActivityIndicatorView {
        let loaderView: UIActivityIndicatorView
        loaderView = UIActivityIndicatorView(style: .whiteLarge)
        containerView.addSubview(loaderView)
        loaderView.center = CGPoint(
            x: playerFrame.midX,
            y: playerFrame.midY
        )
        loaderView.hidesWhenStopped = true
        return loaderView
    }
    
    /// Shows a simple alert with a title and message
    func showAlert(
        title: String = "Alert!",
        message: String = "Description",
        okActionHandler: (() -> Void)? = nil
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            okActionHandler?()
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
    /// Dismisses the current view controller
    private func dismissViewController() {
        dismiss(animated: true)
    }
}

// MARK: - Actions
extension PlayerViewController_iOS {
    
    /// Handles add next video button tap
    @IBAction private func addNextVideo(sender: Any) {
        // Implementation for adding next video
    }
    
    /// Handles play next video button tap
    @IBAction private func playNextVideo(sender: Any) {
        // Implementation for playing next video
    }
    
    /// Handles back button tap, destroys player and dismisses view
    @IBAction private func backButtonClicked(_ sender: Any) {
        vlPlayer?.destroy()
        vlPlayer?.playerVideoAnalyticsDelegate = nil
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Orientation Handling
extension PlayerViewController_iOS {
    
    /// Handles device orientation changes for fullscreen player
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition:nil) { _ in
            guard let orientation = self.view.window?.windowScene?.interfaceOrientation else { return }
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                // If we are on fullscreen and user rotates to portrait, exit fullscreen
                if self.isFullscreen && orientation.isPortrait {
                    self.vlPlayer?.goFullScreen(false)// will trigger onFullScreenChange(false)
                }
            } else {
                if orientation.isLandscape {
                    if !self.isFullscreen {
                        self.isFullscreen = true
                        self.vlPlayer?.goFullScreen(true)
                    }
                } else if orientation.isPortrait {
                    if self.isFullscreen {
                        self.isFullscreen = false
                        self.vlPlayer?.goFullScreen(false)
                    }
                }
            }
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Clean up any non-essential resources
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Handle layout updates if needed
    }
}
