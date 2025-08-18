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
import AVKit

// MARK: - Constants
/// Contains static constants used for player layout and configuration
private enum Constants {
    static let playerMargin: CGFloat = 10
    static let aspectRatio: CGFloat = 9/16
    static let defaultSeekForward: Double = 30.0
    static let defaultSeekBackward: Double = 10.0
    static let playerYPosition: CGFloat = 100
    static let defaultAdUrl = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=1"
}

/// Main view controller for player screen on iOS
class PlayerViewController_iOS: UIViewController {
    /// Player configuration options
    enum Configuration{
        case `default`
        case customTheme
        case custom
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
    var vlPlayer: VLPlayer!
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
    weak var player: AVPlayer?
    var analyticsAdDictionary = AnalyticsAdDictionary()
    var currentAdAssetInfo: VLAdAssetInfo?
    var videoResponse: VLVideoResponseModel?
    private let playerContainerView = UIView()
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
        playerContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerContainerView)
        setupConstraints()
        setupInitialState()
        loadPlayerView()
        
        self.logoutButton.isHidden = true
        
        // Show logout button if user is logged in
        if UserManager.shared.userIdentity != nil {
            self.logoutButton.isHidden = false
        }
    }
    
    func setupConstraints() {
        // Normal constraints (small mode)
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
    private func cleanupResources() {
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
        //        Task { [weak self] in
        let mvpdProvider = UserManager.shared.userIdentity?.mvpdProvider
        
        VLAuthentication.sharedInstance.logout(
            client: .tvProvider(provider: .adobe, tveInitializationConfig: nil),
            mvpdId: mvpdProvider
        ) { [weak self] logoutSuccessful in
            if logoutSuccessful {
                Task { [weak self] in
                    self?.logoutButton.isHidden = true
                    
                    await AppDelegate.shared.logoutUser()
                    self?.vlPlayer.destroy()
                    self?.loadPlayerView()
                }
            }
        }
        //        }
    }
}

// MARK: - Player Setup
extension PlayerViewController_iOS {
    
    /// Loads and configures the player view
    func loadPlayerView() {
        let loaderView = addLoaderView(to: playerContainerView)
        loaderView.startAnimating()
        
        let featureSupported = getPlayerFeaturesSupported()
        let vlBaseUrl = videoList.apiBaseUrl
        
        if shouldUseDirectStream() {
            setupDirectStreamPlayer(baseUrl: vlBaseUrl,
                                    features: featureSupported,
                                    loader: loaderView)
        } else {
            setupContentPlaybackPlayer(baseUrl: vlBaseUrl,
                                       features: featureSupported,
                                       loader: loaderView)
        }
    }
    
    /// Determines if direct stream should be used based on player option
    private func shouldUseDirectStream() -> Bool {
        return playerOptionSelected == .playStreamURL || playerOptionSelected == .playASATURL
    }
    
    /// Sets up player for direct stream playback
    private func setupDirectStreamPlayer(baseUrl: String,
                                         features: VLPlayer.VLPlayerFeatureSupported,
                                         loader: UIActivityIndicatorView) {
        vlPlayer = createVLPlayer()
        configurePlayer()
        
        let isDVREnabled = streamConfig?.isDVR ?? false
        let streamType = VLPlayer.DirectStreamType(
            url: streamUrl ?? "",
            contentId: nil,
            streamConfig: streamConfig,
            drmconfig: drmConfig
        )
        
        let playbackConfig = VLPlayer.DirectStreamPlaybackConfig(
            stream: streamType,
            token: "",
            apiBaseURL: ""
        )
        
        vlPlayer.setSource(
            type: .directStream(playbackConfig),
            customControlsView: getCustomPlayerSkin().view,
            playerFeaturesSupported: features
        ) {
            [weak self] isSuccess,
            playerView,
            contentResponse in
            
            var hasTVE = false
            
            // Check if content has TVE monetization model
            if let video = contentResponse?["video"] as? [String: Any],
               let monetizationModels = video["monetizationModels"] as? [[String: Any]] {
                hasTVE = monetizationModels.contains { $0["type"] as? String == "TVE" }
            }
            
            self?.handlePlayerSetupCompletion(
                isSuccess: isSuccess,
                playerView: playerView,
                isDVREnabled: isDVREnabled,
                loader: loader,
                hasTVE: hasTVE
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
            
            if let contentResponse = contentResponse {
                self?.parseVLVideoResponse(from: contentResponse)
            }
        }
    }
    
    /// Sets up player for content playback (non-direct stream)
    private func setupContentPlaybackPlayer(baseUrl: String,
                                            features: VLPlayer.VLPlayerFeatureSupported,
                                            loader: UIActivityIndicatorView) {
        vlPlayer = VLPlayer(playerType: .default)
        configurePlayer()
        
        if let entitlementData = entitlementData {
            vlPlayer.setEntitlement(data: entitlementData)
        }
        
        let playbackConfig = VLPlayer.ContentPlaybackConfig(
            videoId: videoList.videoId,
            token: vlToken,
            apiBaseURL: baseUrl
        )
        
        vlPlayer.setSource(
            type: .contentPlayback(playbackConfig),
            customControlsView: getCustomPlayerSkin().view,
            playerFeaturesSupported: features
        ) {
            [weak self] isSuccess,
            playerView,
            contentResponse in
            var hasTVE = false
            
            // Check if content has TVE monetization model
            if let video = contentResponse?["video"] as? [String: Any],
               let monetizationModels = video["monetizationModels"] as? [[String: Any]] {
                hasTVE = monetizationModels.contains { $0["type"] as? String == "TVE" }
            }
            
            self?.handlePlayerSetupCompletion(
                isSuccess: isSuccess,
                playerView: playerView,
                isDVREnabled: false,
                loader: loader,
                hasTVE: hasTVE
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
            
            if let contentResponse = contentResponse {
                self?.parseVLVideoResponse(from: contentResponse)
            }
        }
    }
    
    /// Creates a VLPlayer instance, optionally with Bitmovin config
    private func createVLPlayer() -> VLPlayer {
        let playerLicenseKey: String? = ""
        let analyticsLicenseKey: String? = ""
        let userId: String? = nil
        
        if let playerLicenseKey = playerLicenseKey, !playerLicenseKey.isEmpty {
            let licenseConfig = VLBitmovinConfig.VLBitmovinLicenseConfig(
                playerKey: playerLicenseKey,
                analyticsKey: analyticsLicenseKey
            )
            let config = VLBitmovinConfig(license: licenseConfig, userId: userId)
            return VLPlayer(playerType: .bitmovin(config: config))
        }
        return VLPlayer(playerType: .default)
    }
    
    /// Configures player delegates and settings
    private func configurePlayer() {
        videoPlayerControlsView?.videoPlayer = vlPlayer
        vlPlayer.videoPlayerDelegate = self
        vlPlayer.playerVideoAnalyticsDelegate = self
        vlPlayer.enablePlayerBitrateLogs = enableBitrateLogs
        vlPlayer.serverSideAdTrackingDelegate = self
        vlPlayer.castDelegate = self
    }
    
    /// Handles completion of player setup, including TVE checks and UI updates
    private func handlePlayerSetupCompletion(
        isSuccess: Bool,
        playerView: UIView?,
        isDVREnabled: Bool,
        loader: UIActivityIndicatorView,
        hasTVE: Bool
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
                self.checkAuthz(
                    user: user,
                    playerView: playerView,
                    isDVREnabled: isDVREnabled
                )
            } else {
                if isDVREnabled {
                    self.videoPlayerControlsView?.updateControlsBasedOnDVRFlag(isDVREnabled: isDVREnabled)
                }
                self.addPlayer(playerView: playerView)
            }
        }
    }
    
    /// Checks TVE authorization for the user before playback
    private func checkAuthz(user: VLUserIdentity, playerView: UIView, isDVREnabled: Bool){
        let mvpdProvider = user.mvpdProvider ?? ""
        
        VLAuthentication.sharedInstance.checkAuthz(mvpdId: mvpdProvider) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if isDVREnabled {
                        self.videoPlayerControlsView?.updateControlsBasedOnDVRFlag(isDVREnabled: isDVREnabled)
                    }
                    self.addPlayer(playerView: playerView)
                case .failure(let error):
                    self.handleAuthzFailure(error)
                }
            }
        }
    }
    
    /// Handles TVE authorization failure
    private func handleAuthzFailure(_ error: VLAuthenticationErrorCode) {
        self.showAlert(title: "Error", message: "TVE Authorization denied")
    }
    
    /// Adds the player view to the main view and sets up custom UI if enabled
    func addPlayer(playerView: UIView) {
        if enableCustomPlayerUI {
            setupCustomPlayerUI()
        }
       // playerView.frame = playerFrame
        playerContainerView.addSubview(playerView)
        playerView.pinToSuperview(insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
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
            isSubTitleSupported: false,
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
                                                 payWallConfiguration: getPayWallConfiguration(type: .default),
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
            return nil
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
    func showAlert(title: String = "Alert!", message: String = "Description") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
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
        vlPlayer.destroy()
        vlPlayer.playerVideoAnalyticsDelegate = nil
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
                    self.vlPlayer.goFullScreen(false)// will trigger onFullScreenChange(false)
                }
            } else {
                if orientation.isLandscape {
                    if !self.isFullscreen {
                        self.isFullscreen = true
                        self.vlPlayer.goFullScreen(true)
                    }
                } else if orientation.isPortrait {
                    if self.isFullscreen {
                        self.isFullscreen = false
                        self.vlPlayer.goFullScreen(false)
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

extension UIView {
    
    func setupConstraints(superView: UIView, withHeightConstraint: Bool? = false, topOffset: CGFloat = 0) {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self,
                           attribute: .top,
                           relatedBy: .equal,
                           toItem: superView,
                           attribute: .top,
                           multiplier: 1,
                           constant: topOffset).isActive = true
        NSLayoutConstraint(item: self,
                           attribute: .leading,
                           relatedBy: .equal,
                           toItem: superView,
                           attribute: .leading,
                           multiplier: 1,
                           constant: 0).isActive = true
        NSLayoutConstraint(item: self,
                           attribute: .trailing,
                           relatedBy: .equal,
                           toItem: superView,
                           attribute: .trailing,
                           multiplier: 1,
                           constant: 0).isActive = true
        if withHeightConstraint == true {
            NSLayoutConstraint(item: self,
                               attribute: .height,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .notAnAttribute,
                               multiplier: 1,
                               constant: self.bounds.height).isActive = true
        } else {
            NSLayoutConstraint(item: self,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: superView,
                               attribute: .bottom,
                               multiplier: 1,
                               constant: 0).isActive = true
        }
    }
    
    func pinToSuperview(edges: UIRectEdge = .all, insets: UIEdgeInsets = .zero) {
        guard let superview = superview else {
            debugPrint("⚠️ No superview to pin to.")
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        
        var constraints = [NSLayoutConstraint]()
        
        if edges.contains(.top) || edges == .all {
            constraints.append(topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top))
        }
        if edges.contains(.left) || edges == .all {
            constraints.append(leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left))
        }
        if edges.contains(.bottom) || edges == .all {
            constraints.append(bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom))
        }
        if edges.contains(.right) || edges == .all {
            constraints.append(trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.right))
        }
        
        NSLayoutConstraint.activate(constraints)
    }
}
extension UIWindow {
    static var isLandscape: Bool {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows
                .last?
                .windowScene?
                .interfaceOrientation
                .isLandscape ?? false
        } else {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
}
