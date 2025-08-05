//
//  VideoPlaybackController.swift
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
private enum Constants {
    static let playerMargin: CGFloat = 10
    static let aspectRatio: CGFloat = 9/16
    static let defaultSeekForward: Double = 30.0
    static let defaultSeekBackward: Double = 10.0
    static let playerYPosition: CGFloat = 100
    static let defaultAdUrl = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=1"
}

class VideoPlaybackController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet private var debugLogView: UITextView!
    @IBOutlet private weak var addNextButton: UIButton!
    @IBOutlet private weak var playNextButton: UIButton!
    
    // MARK: - Properties
    private var customPaywallView: CustomPaywallView?
    private var videoList: VideoList!
    private var vlPlayer: VLPlayer!
    private var videoPlayerControlsView: CustomVideoControls?
    private var fullScreenView: FullScreenPlayerViewController?
    
    // Configuration Properties
    var enableCustomPlayerUI: Bool = false
    private var enableBitrateLogs: Bool = false
    var entitlementData: VLPlayer.EntitlementData?
    var drmConfig: VLPlayer.DRMConfig?
    var streamConfig: VLPlayer.StreamConfig?
    var loopEnabled: Bool = false
    var autoplayEnabled: Bool = true
    var hideControls: Bool = false
    var muteEnabled: Bool = false
    var streamUrl: String?
    var player: AVPlayer?
    var currentAdAssetInfo: VLAdAssetInfo?
    var videoResponse: VLVideoResponseModel?
    // Private Properties
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
    
    // MARK: - Computed Properties
    private var playerFrame: CGRect {
        let width = UIScreen.main.bounds.width - (Constants.playerMargin * 2)
        let height = width * Constants.aspectRatio
        return CGRect(x: Constants.playerMargin,
                      y: Constants.playerYPosition,
                      width: width,
                      height: height)
    }
    
    private var vlToken: String {
        return AppDelegate.shared.authorizationToken ?? ""
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialState()
        loadPlayerView()
        
        self.logoutButton.isHidden = true
        
        if UserManager.shared.userIdentity != nil {
            self.logoutButton.isHidden = false
        }
    }
    
    deinit {
        cleanupResources()
    }
    
    // MARK: - Setup Methods
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
    
    private func cleanupResources() {
        vlPlayer?.destroy()
        vlPlayer?.playerAdsAnalyticsDelegate = nil
        vlPlayer?.playerVideoAnalyticsDelegate = nil
        videoPlayerControlsView?.removeFromSuperview()
        fullScreenView?.dismiss(animated: false)
    }
    
    // MARK: - Public Configuration
    func prepareView(withPlayerUIOption playerOptionSelected: PlayerUIOptions, videoList: VideoList) {
        self.videoList = videoList
        self.playerOptionSelected = playerOptionSelected
        self.playableVideoId = videoList.videoId
        
        configurePlayerOptions(playerOptionSelected)
    }
    
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
extension VideoPlaybackController {
    
    func loadPlayerView() {
        let loaderView = addLoaderView(to: view)
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
    
    private func shouldUseDirectStream() -> Bool {
        return playerOptionSelected == .playStreamURL || playerOptionSelected == .playASATURL
    }
    
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
            token: vlToken,
            apiBaseURL: baseUrl
        )
        
        vlPlayer.setSource(
            type: .directStream(playbackConfig),
            customControlsView: videoPlayerControlsView,
            playerFeaturesSupported: features
        ) {
            [weak self] isSuccess,
            playerView,
            contentResponse in
            
            var hasTVE = false
            
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
            if let contentResponse = contentResponse {
                self?.parseVLVideoResponse(from: contentResponse)
            }
        }
    }
    
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
            customControlsView: videoPlayerControlsView,
            playerFeaturesSupported: features
        ) {
            [weak self] isSuccess,
            playerView,
            contentResponse in
            var hasTVE = false
            
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
            if let contentResponse = contentResponse {
                self?.parseVLVideoResponse(from: contentResponse)
            }
        }
    }
    
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
        return VLPlayer()
    }
    
    private func configurePlayer() {
        videoPlayerControlsView?.videoPlayer = vlPlayer
        vlPlayer.videoPlayerDelegate = self
        vlPlayer.clientSideAdTrackingDelegate = self
        vlPlayer.playerAdsAnalyticsDelegate = self
        vlPlayer.playerVideoAnalyticsDelegate = self
        vlPlayer.enablePlayerBitrateLogs = enableBitrateLogs
    }
    
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
            
            
            guard let user = UserManager.shared.userIdentity else {
                if isDVREnabled {
                    self.videoPlayerControlsView?.updateControlsBasedOnDVRFlag(isDVREnabled: isDVREnabled)
                }
                self.addPlayer(playerView: playerView)
                return
            }
            
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
    
    // Extract error handling for reuse/centralization
    private func handleAuthzFailure(_ error: VLAuthenticationErrorCode) {
        self.showAlert(title: "Error", message: "TVE Authorization denied")
    }
    
    // Now addPlayer is pure, just presenting the UI
    private func addPlayer(playerView: UIView) {
        if enableCustomPlayerUI {
            setupCustomPlayerUI()
        }
        playerView.frame = playerFrame
        view.addSubview(playerView)
    }
    
    
    private func setupCustomPlayerUI() {
        videoPlayerControlsView?.setupPictureInPicture()
        videoPlayerControlsView?.startPictureInPictureInline(enable: true)
        
        videoPlayerControlsView?.updatePlayerControlsType(playerControlType: self.vlPlayer.isLiveVideo() ? .liveVideoControls : .streamVideoControls)
    }
    
    private func getCustomControls() -> CustomVideoControls {
        let controlsView = CustomVideoControls(frame: playerFrame)
        
        if playerOptionSelected == .customControlWithCustomSeekDuration {
            controlsView.seekBackwardDuration = seekBackwardDuration
            controlsView.seekForwardDuration = seekForwardDuration
        }
        
        return controlsView
    }
    
    private func getPlayerFeaturesSupported() -> VLPlayer.VLPlayerFeatureSupported {
        // use below code for configuring Default paywall view
        /*
         let payWallStyle = VLPlayer.PayWallStyle(errorMessageTextColor: .red, buttonTextColor: .blue, buttonBackgroundColor: .yellow, backgroundColor: nil)
         let payWallTextContent = VLPlayer.PayWallTextContent(errorMessage: "Error", buttontext: nil)
         let payWallThemeConfiguration = VLPlayer.PayWallThemeConfiguration(style: payWallStyle, textContent: payWallTextContent)
         let payWallConfiguration: VLPlayer.PayWallConfiguration = VLPlayer.PayWallConfiguration.default(payWallTheme: payWallThemeConfiguration)
         */
        
        // use below code for custom view
        /*
         //        let customPaywallView = CustomPaywallView()
         //        let payWallConfiguration: VLPlayer.PayWallConfiguration = .custom(view: customPaywallView)
         //        self.customPaywallView = customPaywallView
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
                                                 payWallConfiguration: nil)
    }
}

// MARK: - UI Helpers
extension VideoPlaybackController {
    
    private func addLoaderView(to containerView: UIView) -> UIActivityIndicatorView {
        let loaderView: UIActivityIndicatorView
        
        if #available(iOS 13.0, *) {
            loaderView = UIActivityIndicatorView(style: .large)
            loaderView.color = .black
        } else {
            loaderView = UIActivityIndicatorView(style: .whiteLarge)
        }
        
        containerView.addSubview(loaderView)
        loaderView.center = CGPoint(
            x: playerFrame.midX,
            y: playerFrame.midY
        )
        loaderView.hidesWhenStopped = true
        
        return loaderView
    }
    
    private func showAlert(title: String = "Alert!", message: String = "Description") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
    private func dismissViewController() {
        dismiss(animated: true)
    }
}

// MARK: - Actions
extension VideoPlaybackController {
    
    @IBAction private func addNextVideo(sender: Any) {
        // Implementation for adding next video
    }
    
    @IBAction private func playNextVideo(sender: Any) {
        // Implementation for playing next video
    }
    
    @IBAction private func backButtonClicked(_ sender: Any) {
        vlPlayer.destroy()
        vlPlayer.playerAdsAnalyticsDelegate = nil
        vlPlayer.playerVideoAnalyticsDelegate = nil
        dismissViewController()
    }
}

extension VideoPlaybackController: VLAnalyticsPlayerClientProtocol {
    func playerDidStart(player: AVPlayer?) {
        
    }


    func setAdInfo(adId: String, adName: String, podName: String?, podLength: Double?, podPosition: Int?, podOffset: Double?, startTime: Double?) {
        self.currentAdAssetInfo = VLAdAssetInfo(adId: adId, adName: adName, podName: podName, podLength: podLength, podPosition: podPosition, podOffset: podOffset, startTime: startTime)
    }
    
    
    func setAdInfo(adId: String, adName: String, podName: String?, podLength: Double?, podPosition: Int?, podOffset: Double?, startTime: Double?, adSystem: String?) {
        self.currentAdAssetInfo = VLAdAssetInfo(adId: adId, adName: adName, podName: podName, podLength: podLength, podPosition: podPosition, podOffset: podOffset, startTime: startTime, adSystem: adSystem)
    }
    
    func setAdComplete() {
        self.currentAdAssetInfo = nil
    }
    
    func getAdsInfo() -> VLAdAssetInfo? {
        return self.currentAdAssetInfo
    }
    
    func parseVLVideoResponse(from dictionary: [String: Any]) {
        do {
            // Convert dictionary to JSON Data
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])

            // Decode using JSONDecoder
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            let response = try decoder.decode(VLVideoResponseModel.self, from: jsonData)

            self.videoResponse = response
            
        } catch {
            print("❌ Failed to decode from dictionary:", error)
        }
    }
    
    func getFormattedDateFromTimestamp(timestamp: TimeInterval?) -> String? {
        guard let timestamp = timestamp else {
            return nil
        }
        let date = Date(timeIntervalSince1970: timestamp)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy" // <- DD/MM/YYYY format
        formatter.timeZone = .current       // or use .utc for UTC time
        
        let formattedDate = formatter.string(from: date)
        print("Publish Date: \(formattedDate)")
        return formattedDate
    }
    
    func getVideoInfo() -> VLContentInfo? {
        var streamType: String = ""
        var isContentFree: Bool = false
        var isFullScreen: Bool = false
        
        if let mediaTyp = self.videoResponse?.video?.streamingInfo?.isLiveStream {
            streamType = mediaTyp ? "live" : "vod"
        }

        if let monetizationModel = self.videoResponse?.video?.monetizationModels {
            isContentFree = monetizationModel.contains(where: { $0.type == "FREE" })
        }
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            isFullScreen = appDelegate.isFullScreen
        }
        
        let data = self.videoResponse?.video
        let isFree = !(self.videoResponse?.plans?.isEmpty ?? false) && isContentFree
        let status = isFree ? "free" : "premium"
        let videobroadcast = self.videoResponse?.video?.streamingInfo?.isLiveStream ?? false ? "Broadcast" : "Digital"

        return VLContentInfo(
            id: data?.id,
            title: data?.title,
            seriesTitle: data?.title,
            contentType: streamType,
            airDate: self.getFormattedDateFromTimestamp(timestamp: self.videoResponse?.video?.publishDate),
            streamType: streamType,
            screenSize: isFullScreen ? "FullScreen" : "Normal",
            videostatus: status,
            videotmsid: data?.id,
            videobroadcast: videobroadcast,
            videoInitiate: "Manual"
        )
    }
    
    func trackVideoStart() {
        let eventBuilder = VLEventModelBuilder()
            .eventType(.mediaPlay)
            .contentInfo(getVideoInfo())
            .tvProviderInfo(VLTVProviderInfo(tvProviderName: /*ParentalControlHelper.getUserDetails()?.mvpdProvider*/ "",
                                             requestorId:/* AppConfiguration.shared.tveSettings?.requestorId*/ "")
            )
            .adsInfo(getAdsInfo())
            .setPlayer(player)
            .build()
        VLAnalytics.shared.trackEvent(data: eventBuilder)
    }
}

// MARK: - VideoPlaybackDelegate
extension VideoPlaybackController: videoPlaybackDelegate {
    
    func videoStarted(timestamp: Double, playerTag: String) {
        videoPlayerControlsView?.setPlayButtonState(state: true)
        videoPlayerControlsView?.updateTimeLabelOnStart()
        self.trackVideoStart()
    }
    
    func videoPause(timestamp: Double, playerTag: String) {
        videoPlayerControlsView?.setPlayButtonState(state: false)
    }
    
    func videoResume(timestamp: Double, playerTag: String) {
        videoPlayerControlsView?.setPlayButtonState(state: true)
    }
    
    func videoFinished(playerTag: String) {
        videoPlayerControlsView?.setPlayButtonState(state: false)
    }
    
    func videoPlaybackError(currentTime: Double, errorMessage: String, errorCode: String, playerTag: String) {
        videoPlayerControlsView?.setPlayButtonState(state: false)
        
        if !errorMessage.isEmpty {
            showAlert(message: errorMessage)
        }
    }
    
    func videoFetchError(error: VLError?, playerTag: String?, contentResponse: Dictionary<String, AnyObject>?) {
        let errorDescription = buildErrorDescription(from: error)
        
        print("Error VL:", errorDescription)
        print("VideoFetchError: contentResponse:", contentResponse as Any)
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(message: errorDescription)
            self?.customPaywallView?.update(error?.errorMessage ?? "Error occurred while fetching content")
        }
    }
    
    private func buildErrorDescription(from error: VLError?) -> String {
        guard let error = error else { return "Unknown error occurred" }
        
        return """
        Is content playable - \(error.isPlayable)
        Content Fetched successfully - \(error.isSuccess)
        Error Code - \(error.errorCode)
        Error Message - \(error.errorMessage)
        Error VL Code - \(error.vl_errorCode)
        """
    }
    
    func videoPlayerProgressByEverySecond(currentTime: Double, totalTime: Double, playerTag: String, parsedTimeStamp: String?) {
        let elapsedTime = calculateElapsedTime(currentTime: currentTime, totalTime: totalTime)
        
        videoPlayerControlsView?.updateTimeLabel(
            timeRemaining: totalTime - currentTime,
            elapsedTime: currentTime
        )
        
        let sliderValue = getSliderDuration(currentTime: elapsedTime, totalDuration: totalTime)
        videoPlayerControlsView?.updateSliderDuration(sliderValue: sliderValue)
    }
    
    private func calculateElapsedTime(currentTime: Double, totalTime: Double) -> Double {
        guard let _ = vlPlayer.getStartOverTime() else { return currentTime }
        return currentTime > totalTime ? totalTime : currentTime
    }
    
    private func getSliderDuration(currentTime: Double, totalDuration: Double) -> Double {
        guard totalDuration > 0, currentTime <= totalDuration else { return 0 }
        return currentTime / totalDuration
    }
    
    func playerBitrateDebugLogs(logString: String) {
        guard enableBitrateLogs else { return }
        
        debugLogView.isHidden = false
        debugLogView.text.append(logString + "\n\n")
        
        let range = NSRange(location: debugLogView.text.count - 1, length: 0)
        debugLogView.scrollRangeToVisible(range)
    }
}

// MARK: - FullScreenDelegate
extension VideoPlaybackController: fullScreenDelegate {
    
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

// MARK: - Picture in Picture Delegates
extension VideoPlaybackController {
    
    func pictureInPictureSetupCompleted(isPIPSelected: Bool) {
        print(#function)
    }
    
    func pictureInPictureWillStart() {
        print(#function)
    }
    
    func pictureInPictureDidStart() {
        vlPlayer.requireLinearPlaybackInPictureInPicture(isRequired: false)
    }
    
    func pictureInPictureRestoreFullPlayer() {
        print(#function)
    }
    
    func pictureInPictureWillStop() {
        print(#function)
    }
    
    func pictureInPictureDidStop() {
        print(#function)
    }
    
    func pictureInPictureDidFailedToStart(error: VLError, playerTag: String) {
        print(#function)
    }
}

// MARK: - ClientSideAdTrackingDelegate
extension VideoPlaybackController: ClientSideAdTrackingDelegate {
    
    func additionalTrackingDetailsForClientSideAdTracking() -> [String: Any]? {
        return ["hello": "value"]
    }
    
    func initalisationForExternalAdTrackingSdk(playerView: UIView, playerSize: CGSize, completion: (() -> Void)) {
        completion()
    }
    
    func clientSideAdTrackingEvents(trackingEventType: VLPlayerLib.VLPlayer.AdsEventType, eventTrackingProperties: [String: Any]) {
        // Handle ad tracking events
    }
}

// MARK: - Authentication
extension VideoPlaybackController {
    
    func loginWithTVE() {
        debugPrint("Login with TVE called")
        proceedTVELogin()
    }
    
    private func proceedTVELogin() {
        VLAuthentication.sharedInstance.initiateAuthentication(
            authenticationType: .signin,
            authenticationObject: nil,
            authenticationClient: .tvProvider(provider: .adobe, tveInitializationConfig: nil),
            presentingViewController: self,
            beacon: VLBeacon.getInstance()
        ) { [weak self] userIdentity, errorCode in
            DispatchQueue.main.async {
                if userIdentity == nil, let codeString = errorCode?.codeString {
                    self?.showAlert(message: codeString)
                    return
                }
                
                UserManager.shared.userIdentity = userIdentity
                AppDelegate.shared.authorizationToken = userIdentity?.authorizationToken
                self?.vlPlayer.destroy()
                self?.vlPlayer.playerAdsAnalyticsDelegate = nil
                self?.vlPlayer.playerVideoAnalyticsDelegate = nil
                self?.loadPlayerView()
                self?.logoutButton.isHidden = false
            }
        }
    }
}

// MARK: - ChromeCast
extension VideoPlaybackController {
    
    func chromeCastConnectionStatusUpdate(isConnected: Bool) {
        print("Cast connected:", isConnected)
    }
    
    func getChromeCastConnectedStatus() {
        print("Cast connected:", vlPlayer.getChromeCastConnectedStatus())
    }
    
    func seekStarted(time: TimeInterval) {
        print("Seek Started: \(time)")
    }
    
    func seekCompleted(time: TimeInterval) {
        print("Seek Completed: \(time)")
    }
}

// MARK: - Orientation Handling
extension VideoPlaybackController {
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            
            if size.width > size.height {
                if appDelegate?.isFullScreen == false {
                    self.vlPlayer.goFullScreen()
                }
            }
            else {
                if appDelegate?.isFullScreen == true {
                    self.vlPlayer.removeFullScreen()
                }
            }
        }, completion: nil)
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


extension VideoPlaybackController: VLAuthPlayerDelegate {
    func reloadPlayer() {
        
    }
    
    func terminatePlayer() {
        
    }
}
