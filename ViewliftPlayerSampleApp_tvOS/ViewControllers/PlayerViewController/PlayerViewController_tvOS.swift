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
import SwiftUI

private enum Constants {
    static let playerMargin: CGFloat = 10
    static let aspectRatio: CGFloat = 9/16
    static let defaultSeekForward: Double = 30.0
    static let defaultSeekBackward: Double = 10.0
    static let playerYPosition: CGFloat = 100
    static let defaultAdUrl = "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/single_preroll_skippable&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&correlator="
}

// Main player view controller for tvOS, handles player setup, UI, and playback logic
class PlayerViewController_tvOS: UIViewController {
    enum Configuration{
        case `default`
        case customTheme
        case custom
        case native
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
    var isChapteringCuePointEnable: Bool = true
    var isGuestUser: Bool = false
    var videoPlayerControlsView: VLCustomPlayerControlsView?
    var customPaywallView: CustomPaywallView?
    var portraitConstraints: [NSLayoutConstraint] = []
    var landscapeConstraints: [NSLayoutConstraint] = []
    weak var player: AVPlayer?
    var currentAdAssetInfo: VLAdAssetInfo?
    var videoResponse: VLVideoResponseModel?
    var enableCustomAdUI: Bool = false
    var autoPlayListdataManager: AutoPlayDataManager?
    internal var autoPlayView: AutoPlayView?
    let timerLabel = UILabel()
    internal var isFullScreen: Bool = false
    let testButton = UIButton(type: .system)
    
    // Watch History View Properties
    private var watchHistoryHostingController: UIHostingController<WatchHistoryView>?
    private var watchHistoryView: WatchHistoryView?
    private var watchedTime: Int = 0
    private var watchHistoryInterval: Int = 30
    private var watchedPercentage: Double = 0
    private var watchHistoryThreshold: Double = 95.0
    private var watchHistoryEnabled: Bool = true
    private var doneWatching: Bool = false
    
    var totalAdsDuration: Double = 0.0
    var channelId: [String] = [] {
        didSet {
            self.channelkey = self.channelId.joined(separator: ",")
        }
    }
    let loaderView = UIActivityIndicatorView(style: .large)

    var channelkey: String = ""
    var chapteringCuePoints: [ChapteringCuePoint] = []
    
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
        if isChapteringCuePointEnable {
            chapteringCuePoints = loadChapteringCuePoints()
        }
        updateConstraintsForCurrentOrientation()
        self.createAutoPlayMetaData()
        self.timerLabel.isHidden = true
        
        Task {
            await self.loadPlayerView()
        }
        
        createButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        VLAnalytics.shared.startObservingPlayerEvents()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        VLAnalytics.shared.stopObservingPlayerEvents()
    }
    
    private func addLoaderView(to containerView: UIView) -> UIActivityIndicatorView {
        containerView.addSubview(loaderView)
        loaderView.backgroundColor = .red
        loaderView.hidesWhenStopped = true
        loaderView.center(in: containerView)
        return loaderView
    }

    
    // Loads and configures the player view
    func loadPlayerView() async {
        let loaderView = addLoaderView(to: playerContainerView)
        loaderView.startAnimating()
        let featureSupported = getPlayerFeaturesSupported()
        let vlBaseUrl = self.videoList.apiBaseUrl
        let vlToken = AppDelegate.shared.authorizationToken ?? ""
        // Not checking for Temp Pass if playing from direct URL in Sample APP
        if UserManager.shared.userIdentity?.tveUserId == nil && !isPlayingFromURL(){
                //check if ealier temp pass was created but not expired
                self.invalidatePlayerTempPassIfOutOfWindow()

                //request for temp pass
                await self.getTempPassPayload()
        }
        
        let playerLicenseKey: String? = ""
        let analyticsLicenseKey: String? = ""
        let userId: String? = nil
        let vlBeaconURL = ""
        // Initialize player with license if available

        if let playerLicenseKey = playerLicenseKey, !playerLicenseKey.isEmpty {
            vlPlayer = VLPlayer(playerType: .bitmovin(config: VLBitmovinConfig(license: VLBitmovinConfig.VLBitmovinLicenseConfig(playerKey: playerLicenseKey, analyticsKey: analyticsLicenseKey), userId: userId)))
        }else{
            vlPlayer = VLPlayer(playerType: .default)
        }
        // Select playback source type based on user option
        let playbackSourceType: VLPlayer.PlaybackSourceType
        if isPlayingFromURL(){
        
            playbackSourceType =
                .directStream(
                    VLPlayer
                        .DirectStreamPlaybackConfig(
                            stream: VLPlayer
                                .DirectStreamType(
                                    url: streamUrl ?? "",
                                    streamConfig: VLPlayer
                                        .StreamConfig(
                                            isLive: streamConfig?.isLive,
                                            isDVR: streamConfig?.isDVR,
                                            isSSAIEnabled: false
                                        ),
                                    drmconfig: drmConfig
                                ),
                            token: vlToken,
                            apiBaseURL: vlBaseUrl,
                            beaconBaseURL: vlBeaconURL,
                            mediaMetaDataInfo: nil
                        )
                )
            
        } else {
            let adobePassPayload = try? AppDelegate.shared.adobePlayerTempPass[self.channelkey]?.getTempToken() ?? nil
            
            playbackSourceType =
                .contentPlayback(
                    VLPlayer
                        .ContentPlaybackConfig(
                            videoId: self.videoList.videoId,
                            token: vlToken,
                            apiBaseURL: vlBaseUrl, beaconBaseURL: vlBeaconURL,adobeTempPassPayload: nil
                        )
                )
        }
        // Set delegates for player events and analytics
        vlPlayer?.videoPlayerDelegate = self
        vlPlayer?.videoPlayerDatasource = self
        
        // Set delegates for SSAID events
        vlPlayer?.serverSideAdTrackingDelegate = self
        
//        let epgProgramDetails = VLEPGProgramDetails(id: "89e9e253-3981-4684-a6cb-2a03a0353713", channelId: "60c9d965-ef28-4cd6-a7d5-9a433eb2a923", channelName: "cnbc", programId: "EP024874280301", programTitle: "Dateline", subType: "Series", programStartTime: 12.0, programEndTime: 24.0, subTitle: "Series")
//        vlPlayer?.playerVideoAnalyticsDelegate = AnalyticsHelper.shared
        // Set entitlement if available
        if let entitlementData{
            vlPlayer?.setEntitlement(data: entitlementData)
        }
        let autoPlayList = autoPlayListdataManager?.getAutoPlayUrlList()// pass this for autoplay in nextPlaybackList
        
        // Set player source and handle completion
        vlPlayer?.setSource(type: playbackSourceType,
                            vlPlayerTag: "1", customControlsView: nil,adUrl: nil,
                            playerFeaturesSupported: featureSupported, nextPlaybackList: nil
                        ) { [weak self] isSuccess, playerView, contentResponse in
            DispatchQueue.main.async {
                if let contentResponse = contentResponse {
                    self?.videoResponse = AnalyticsHelperV2.shared.parseVLVideoResponse(from: contentResponse)
                }
                
                var hasTVE = false
                
                if let video = contentResponse?["video"] as? [String: Any],
                   let monetizationModels = video["monetizationModels"] as? [[String: Any]] {
                    hasTVE = monetizationModels.contains { $0["type"] as? String == "TVE" }
                }
                let plans = contentResponse?["plans"] as? [[String: Any]] ?? []
                let channelIds = plans
                    .flatMap { $0["planDetails"] as? [[String: Any]] ?? [] }
                    .flatMap { $0["channelIds"] as? [String] ?? [] }
                self?.handlePlayerSetupCompletion(playerView: playerView, hasTVE: hasTVE, channelIds: channelIds)
                
                // Add watch history view after player is set up (only if not in full screen)
                if self?.isFullScreen == false {
                    if self?.watchHistoryView == nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.addWatchHistoryView()
                        }
                    }
                }
            }
        }
    }
    
   private func isPlayingFromURL() -> Bool{
        return playerOptionSelected == .playStreamURL || playerOptionSelected == .playASATURL
    }

    private func loadChapteringCuePoints() -> [ChapteringCuePoint] {
        guard let url = Bundle.main.url(forResource: "chaptering", withExtension: "json"),
              let rawString = try? String(contentsOf: url, encoding: .utf8),
              let jsonStart = rawString.firstIndex(of: "{") else {
            return []
        }

        let jsonString = String(rawString[jsonStart...])
        guard let data = jsonString.data(using: .utf8) else { return [] }

        do {
            let response = try JSONDecoder().decode(ChapteringCuePointResponse.self, from: data)
            return response.items.segments.sorted { $0.startTime < $1.startTime }
        } catch {
            debugPrint("Chaptering cue point parse error: \(error)")
            return []
        }
    }

    private struct ChapteringCuePointResponse: Decodable {
        let items: Items

        enum CodingKeys: String, CodingKey {
            case items = "Items"
        }

        struct Items: Decodable {
            let segments: [ChapteringCuePoint]

            enum CodingKeys: String, CodingKey {
                case segments = "Segments"
            }
        }
    }
    
    // Handles player setup completion, checks for TVE authorization
    private func handlePlayerSetupCompletion(
        playerView: UIView?,
        hasTVE: Bool,
        channelIds: [String]
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let playerView = playerView else { return }
            
            guard let user = UserManager.shared.userIdentity else {
                self.addPlayerViewToContainer(playerView)
                return
            }
            // If user is TVE and content requires TVE, check authorization
            if user.tveUserId != nil && hasTVE {
                Task {
                    await self.checkAuthz(
                        user: user,
                        playerView: playerView,
                        channelIds: channelIds
                    )
                }
            } else {
                self.addPlayerViewToContainer(playerView)
            }
        }
    }
    
    // Checks TVE authorization for the user
    private func checkAuthz(user: VLUserIdentity, playerView: UIView,channelIds: [String] = []) async {
        let mvpdProvider = user.mvpdProvider ?? ""
        
        do {
            let response = try await VLAuthentication.sharedInstance.checkAdobeDecisionsAuthorize(
                mvpdId: mvpdProvider,
                channelIds: channelIds
            )
            
            switch response {
            case .success(_):
                self.addPlayerViewToContainer(playerView)
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
    
    // Handles TVE authorization failure
    private func handleAuthzFailure(_ error: VLAuthenticationErrorCode) {
        switch error {
        case .adobeErrorResponse(let statusCode, let data, let errorMessage, let shouldPerformLogout):
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
    
    // Updates constraints based on current orientation
    func updateConstraintsForCurrentOrientation() {

        NSLayoutConstraint.deactivate(portraitConstraints + landscapeConstraints)

        if isFullScreen {
            NSLayoutConstraint.activate(landscapeConstraints)
        } else {
            NSLayoutConstraint.activate(portraitConstraints)
        }
    }
    
    func changeLayout() {
        isFullScreen.toggle()
        
        // Remove watch history when going to full screen
        if isFullScreen {
            hideWatchHistoryView()
        } else {
            // Add watch history when exiting full screen
            unhideWatchHistoryView()
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
            self.updateConstraintsForCurrentOrientation()
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    
    // Sets up portrait and landscape constraints for the player container
    func setupConstraints() {
        // Setup timerLabel properties (but don't add as subview here)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.textColor = .white
        timerLabel.backgroundColor = .black
        timerLabel.textAlignment = .center
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 32, weight: .heavy)
        timerLabel.text = "00:00"
        timerLabel.isHidden = true

        // Prepare playerContainerView layout constraints (your existing logic)
        portraitConstraints = [
            playerContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            playerContainerView.heightAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 9.0 / 16.0)
        ]

        landscapeConstraints = [
            playerContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
    }


    // Adds the player view to the container and sets constraints
    func addPlayerViewToContainer(_ playerView: UIView) {
        self.vlPlayer?
            .setAnalyticsInfo(
                mediaAnalyticsInfo: MediaAnalyticsInfo(
//                    contentInfo: VLContentInfoAnalytics(videonetwork: "test"),
                    playerInfo: AnalyticsHelperV2.shared.getPlayerInfo(),
                    tvProviderInfo: AnalyticsHelperV2.shared.getTVEProviderInfo()
                )
            )
        
        timerLabel.removeFromSuperview()
        
        // Add player view first (fills container)
        playerContainerView.addSubview(playerView)
        playerContainerView.backgroundColor = .white
        playerView.backgroundColor = .lightGray
        playerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: playerContainerView.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor)
        ])

        // Now add timerLabel *after* all content, so it's on top
        playerContainerView.addSubview(timerLabel)
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: playerContainerView.topAnchor, constant: 16),
            timerLabel.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor, constant: 16),
            timerLabel.heightAnchor.constraint(equalToConstant: 100),
            timerLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])

        playerContainerView.bringSubviewToFront(timerLabel)
        playerContainerView.bringSubviewToFront(loaderView)
    }


    // Returns player features supported configuration
    private func getPlayerFeaturesSupported() -> VLPlayer.VLPlayerFeatureSupported {
        let customMacros  = ["VIEWLIFT_USER_AGENT": Utility.sharedUtility.getUserAgent()]
        // See VLPlayer documentation for available macros
        return VLPlayer.VLPlayerFeatureSupported(appMacrosList: customMacros,
                                                 fullScreenOnly: isFullScreen,
                                                 isCustomLoaderAdded: false,
                                                 shouldStartPictureInPictureInline: true,
                                                 loopVideoPlayback: self.loopEnabled,
                                                 mutePlayback: self.muteEnabled,
                                                 customPlayerControlsColor: nil,
                                                 chromecastCustomReceiver: nil,
                                                 controlsVisibility: .auto,
                                                 payWallConfiguration: .disabled,
                                                 playerControlsViewConfiguration: getPlayerControlsViewConfiguration(type: .customTheme),
                                                 autoPlayConfiguration: getAutoPlayConfig(type: .default),
                                                 isServerSideAdTrackingEnabled: true,
                                                 watchHistoryResumeTime: Double(watchedTime),
                                                 watchHistoryTimeInterval: self.watchHistoryInterval,
                                                 watchHistoryEnabled: self.watchHistoryEnabled)
                                                 isChapteringCuePointEnable: isChapteringCuePointEnable,
                                                 chapteringCuePoints: chapteringCuePoints.map {
                                                    VLPlayer.ChapteringCuePoint(startTime: $0.startTime,
                                                                                label: $0.label,
                                                                                thumbnail: $0.thumbnail,
                                                                                eventStartUtc: $0.eventStartUtc,
                                                                                stocks: $0.stocks)
                                                 },
                                                 featureFlags: FeatureFlags(shouldEnablePlayPauseOnLiveStream: true))
    }
    
    // Returns player controls view configuration based on type
    private func getPlayerControlsViewConfiguration(type: Configuration) -> VLPlayer.PlayerControlsViewConfiguration? {
        switch type {
        case .customTheme:
            // Configure default player controls view with custom theme
            let style = VLPlayer.PlayerControlsViewStyle(sliderColor: .darkGray, sliderProgressColor: .white, smallScreenBorderColor: .green, fullScreenBorderColor: .red, captionsOnOffStatusColor: .red)
            let textContent = VLPlayer.PlayerControlsViewTextContent(slowmoText: "SLOWMO", liveText: "LIVE", startFromBeginningText: "START FROM BEGINNING", closeCaptionHeaderText: "CLOSE CAPTION", closeCaptionText: "CLOSE CAPTION", settingHeaderText: "SETTIING", playbackQualityText: "PLAYBACK QUALITY", subtitlesOnText: "ON", subtitlesOffText: "OFF")
            let playerControlsConfig = PlayerControlsConfig(isSettingsSupported: true, isSubTitleSupported: true, isSlowMoSupported: false,isStartFromBeginningSupported: false,isCaptionsOnOffTextSupported: true , remoteSeekSupport: .both(skip: .dynamic))
            let controlsTheme = VLPlayer.PlayerControlsViewThemeConfiguration(style: style, textContent: textContent, playerControlsConfig: playerControlsConfig)
            let playerControlsViewConfiguration: VLPlayer.PlayerControlsViewConfiguration = .default(controlsTheme: controlsTheme)
            return playerControlsViewConfiguration
        case .custom:
            // Use a custom controls view
            let view = VLCustomPlayerControlsView(frame: .zero, config: nil, isChapteringCuePointEnable: isChapteringCuePointEnable)
            view.updateTitleLabel(text: nil)
            view.delegate = self
            if isChapteringCuePointEnable {
                view.configureChapteringCuePoints(chapteringCuePoints)
            }
            let playerControlsViewConfiguration: VLPlayer.PlayerControlsViewConfiguration = .custom(view: view)
            self.videoPlayerControlsView = view
            return playerControlsViewConfiguration
        case .native:
            let playerControlsViewConfiguration: VLPlayer.PlayerControlsViewConfiguration = .default()
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
        case .native:
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
        removeWatchHistoryView()
        vlPlayer?.destroy()
        removeController()
    }
    
    /// Cleans up player and UI resources
    internal func cleanupResources() {
        vlPlayer?.destroy()
        vlPlayer?.playerVideoAnalyticsDelegate = nil
        videoPlayerControlsView?.removeFromSuperview()
    }
    
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
        if let presentedVC = self.presentedViewController {
            // Check if presented VC can present (not already presenting)
            if presentedVC.presentedViewController == nil {
                presentedVC.present(alertController, animated: true)
            } else {
                // Find top-most VC that can present
                self.findTopPresentableVC()?.present(alertController, animated: true)
            }
        } else {
            self.present(alertController, animated: true)
        }
        
    }
    
    private func findTopPresentableVC() -> UIViewController? {
        var topController: UIViewController? = self
        
        while topController?.presentedViewController != nil {
            topController = topController?.presentedViewController
            if let nav = topController as? UINavigationController {
                topController = nav.topViewController
            }
        }
        
        return topController
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
        guard let vlPlayer else { return }
        if vlPlayer.isPlaying() {
            vlPlayer.pause()
        } else {
            vlPlayer.play()
        }
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
    func getTrickPlayData(_ value: Double) async -> (image: UIImage?, time: String?) {
        await self.vlPlayer?.getTrickPlayData(value) ?? (nil, nil)
    }
}

extension PlayerViewController_tvOS{
    
    internal func createButton(){
        testButton.translatesAutoresizingMaskIntoConstraints = false
        testButton.addTarget(self, action: #selector(closeTapped), for: .primaryActionTriggered)
        testButton.setTitle("Tap!\nFull Screen", for: .normal)
        testButton.titleLabel?.numberOfLines = 2
        testButton.titleLabel?.textAlignment = .center
        view.addSubview(testButton)
        testButton.backgroundColor = .lightGray
        NSLayoutConstraint.activate([
            testButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            testButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            testButton.heightAnchor.constraint(equalTo: playerContainerView.heightAnchor)
        ])
        testButton.isHidden = isFullScreen
        setupChapteringTimeEntry()
    }
    
    @objc private func closeTapped() {
        
        debugPrint("closeTapped")
        vlPlayer?.goFullScreen(true)
       
    }
    
    func performLogout(isForceLogout: Bool = false) {
        let mvpdProvider = UserManager.shared.userIdentity?.mvpdProvider
        
        VLAuthentication.sharedInstance.logout(
            client: .tvProvider(provider: .adobe, tveInitializationConfig: nil),
            mvpdId: mvpdProvider
        ) { [weak self] logoutSuccessful in
            if logoutSuccessful {
                Task { [weak self] in
                    AnalyticsHelperV2.shared.triggerSignoutAnalytics()
                    
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

// MARK: - Watch History View Management
extension PlayerViewController_tvOS: WatchHistoryDelegate {
    
    /// Adds the Watch History SwiftUI view under the player container
    /// - Parameters:
    ///   - topMargin: Top spacing from playerContainerView (default: 20)
    func addWatchHistoryView(topMargin: CGFloat = 20) {
        // Remove existing watch history view if present
        removeWatchHistoryView()
        
        // Create SwiftUI view with bindings
        var watchHistoryView = WatchHistoryView(
            watchedTime: Binding(
                get: { self.watchedTime },
                set: { self.watchedTime = $0 }
            ),
            watchedPercentage: Binding(
                get: { self.watchedPercentage },
                set: { self.watchedPercentage = $0 }
            ),
            doneWatching: Binding(
                get: { self.doneWatching },
                set: { self.doneWatching = $0 }
            )
        )
        
        // Set delegate
        watchHistoryView.delegate = self
        
        // Store reference to the view
        self.watchHistoryView = watchHistoryView
        
        // Create hosting controller
        let hostingController = UIHostingController(rootView: watchHistoryView)
        watchHistoryHostingController = hostingController
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Configure view
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        
        // Set up constraints
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: playerContainerView.bottomAnchor, constant: topMargin),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        self.unhideWatchHistoryView()
    }
    
    func hideWatchHistoryView() {
        guard let hostingController = watchHistoryHostingController else { return }
        
        hostingController.view.isHidden = true
    }
    
    func unhideWatchHistoryView() {
        guard let hostingController = watchHistoryHostingController else { return }
        
        hostingController.view.isHidden = false
    }
    
    
    /// Removes the Watch History view if it exists
    func removeWatchHistoryView() {
        guard let hostingController = watchHistoryHostingController else { return }
        
        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
        watchHistoryHostingController = nil
        watchHistoryView = nil
    }
    
    /// Updates the watch history display values
    /// - Parameters:
    ///   - watchedTime: Time watched in seconds
    ///   - watchedPercentage: Percentage of video watched (0-100)
    ///   - doneWatching: Whether the video is complete
    func updateWatchHistoryDisplay(watchedTime: Double, watchedPercentage: Double) {
        var doneWatching: Bool = false
        if watchedPercentage >= self.watchHistoryThreshold {
            doneWatching = true
        }
        // Update through the shared singleton instance
        WatchHistoryData.shared.update(
            watchedTime: Int(watchedTime),
            watchedPercentage: watchedPercentage,
            doneWatching: doneWatching
        )
        
        // Also keep local properties in sync for backward compatibility
        self.watchedTime = Int(watchedTime)
        self.watchedPercentage = watchedPercentage
        self.doneWatching = doneWatching
    }
    
    /// Gets the current configuration from the watch history view
    /// - Returns: Dictionary with current configuration values
    func getWatchHistoryConfiguration() -> [String: Any]? {
        return watchHistoryView?.getCurrentConfiguration()
    }
    
    // MARK: - WatchHistoryDelegate
    
    func didTapApply(isEnabled: Bool, interval: String, threshold: String, resume: String) {
        print("Watch History Apply Tapped:")
        print("  - Enabled: \(isEnabled)")
        print("  - Interval: \(interval)s")
        print("  - Threshold: \(threshold)%")
        print("  - Resume: \(resume)s")
        
        self.watchedTime = Int(resume) ?? 0
        self.watchHistoryInterval = Int(interval) ?? 0
        self.watchHistoryThreshold = Double(threshold) ?? 0
        let videoWatchPercentage = (self.vlPlayer?.getCurrentVideoDuration() != nil) ? (Double(self.watchedTime) / Double(self.vlPlayer?.getCurrentVideoDuration() ?? 0) * 100): 0.0
        print("Watched Percentage = " + String(videoWatchPercentage))
        self.updateWatchHistoryDisplay(watchedTime: Double(self.watchedTime), watchedPercentage: videoWatchPercentage)
        self.cleanupResources()
        Task { [weak self] in
            await self?.loadPlayerView()
        }
    }
    
    func updateWatchHistory(_ isEnabled: Bool) {
        self.watchHistoryEnabled = isEnabled
        self.vlPlayer?.setWatchHistoryEnabledForPartner(isEnabled)
        print("Watch history tracking: \(isEnabled ? "enabled" : "disabled")")
extension PlayerViewController_tvOS: VideoPlayerDataSource{
    func isUserLoggedIn() -> Bool{
        return true
    }
}

