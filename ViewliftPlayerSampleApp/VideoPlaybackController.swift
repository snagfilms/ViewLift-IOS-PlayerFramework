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

class VideoPlaybackController: UIViewController, videoPlaybackDelegate, UITableViewDelegate, UITableViewDataSource, fullScreenDelegate, ClientSideAdTrackingDelegate {
    private var customPaywallView: CustomPaywallView?
    @IBOutlet var playersTableView:UITableView!
    @IBOutlet var debugLogView:UITextView!
    @IBOutlet weak var addNextButton: UIButton!
    @IBOutlet weak var playNextButton: UIButton!
    private var videoList:VideoList!
    var enableCustomPlayerUI:Bool = false
    var isGuestUser: Bool = false
    private var enableBitrateLogs:Bool! = false
    private var videoPlayerArray: Array<Dictionary<Int, VLPlayer>>?
    private var videoPlayerControlsArray: Array<Dictionary<Int, CustomVideoControls>>?
    private var indexPathArray: Array<IndexPath>?
    private var fullScreenView: FullScreenPlayerViewController?
    private var nextVideoLists:[String] = [] {
        didSet {
            addNextButton.isEnabled = nextVideoLists.count > 0 ? true : false
        }
    }
    lazy private var addedNextVideoList:[String] = [] {
        didSet {
            playNextButton.isEnabled = addedNextVideoList.count > 0 ? true : false
        }
    }
    private var playableVideoId:String?
    private var seekForwardDuration:Double = 30.0
    private var seekBackwardDuration:Double = 10.0
    private var adUrl:String?
    private var playerOptionSelected:PlayerUIOptions!
    var entitlementData: VLPlayer.EntitlementData?
    var drmConfig: VLPlayer.DRMConfig?
    var streamConfig: VLPlayer.StreamConfig?
    var loopEnabled: Bool = false
    var autoplayEnabled: Bool = true
    var hideControls: Bool = false
    var muteEnabled: Bool = false
    var streamUrl: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func prepareView(withPlayerUIOption playerOptionSelected:PlayerUIOptions, videoList:VideoList) {
        self.videoList = videoList
        self.playerOptionSelected = playerOptionSelected
        if playerOptionSelected == .customControlWithDebugLog || playerOptionSelected == .debugLogEnabled {
            self.enableBitrateLogs = true
        }
        if playerOptionSelected == .customControl || playerOptionSelected == .customControlWithDebugLog || playerOptionSelected == .customControlWithCustomSeekDuration {
            self.enableCustomPlayerUI = true
        }
        if playerOptionSelected == .adsEnabled {
            self.adUrl = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=1"
        }
        self.playableVideoId = self.videoList.videoId
        self.proceedFutherWithTableInitialisation()
        self.nextVideoLists = self.videoList.nextVideoList?.map({$0.videoId}) ?? []
        self.playNextButton.isEnabled = false
    }
    
    private func proceedFutherWithTableInitialisation() {
        self.indexPathArray = Array.init()
        self.videoPlayerArray = Array.init()
        self.videoPlayerControlsArray = Array.init()
        self.playersTableView.reloadData()
    }
    
    //MARK: TableView Delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    private func getPlayerFeaturesSupported() -> VLPlayer.VLPlayerFeatureSupported {
        // use below code for default configuration
        /*
         let payWallStyle = VLPlayer.PayWallStyle(errorMessageTextColor: .red, buttonTextColor: .blue, buttonBackgroundColor: .yellow, backgroundColor: nil)
         let payWallTextContent = VLPlayer.PayWallTextContent(errorMessage: "Error", buttontext: nil)
         let payWallThemeConfiguration = VLPlayer.PayWallThemeConfiguration(style: payWallStyle, textContent: payWallTextContent)
         let payWallConfiguration: VLPlayer.PayWallConfiguration = VLPlayer.PayWallConfiguration.default(payWallTheme: payWallThemeConfiguration)
         */
        
        // use below code for custom configuration
        /*
         //        let customPaywallView = CustomPaywallView()
         //        let payWallConfiguration: VLPlayer.PayWallConfiguration = .custom(view: customPaywallView)
         //        self.customPaywallView = customPaywallView
         */
        let playerControls = PlayerControlsColor(iconColor: "",textColor: "", progressBarBGColor: "", progressBarColor: "")
        return VLPlayer.VLPlayerFeatureSupported(fullScreenOnly: false,
                                                 isCustomLoaderAdded: false,
                                                 shouldStartPictureInPictureInline: true,
                                                 autoPlayEnabled: self.autoplayEnabled,
                                                 loopVideoPlayback: self.loopEnabled,
                                                 hideVideoControls: self.hideControls,
                                                 mutePlayback: self.muteEnabled,
                                                 customPlayerControlsColor: nil,
                                                 clientSideAdTrackingDetails: VLPlayer.VLClientSideAdTrackingDetails.init(isClientSideAdTrackingEnabled: true, isWTAEnabled: true), showPlayerControlAlways: false,
                                                 supportsChromeCast: true,
                                                 chromecastCustomReceiver: nil,
                                                 playerResponseRequired:true,
                                                 preGameStartTime: nil,
                                                 appMacrosList: nil, vlBeacon: VLBeacon.getInstance(), payWallConfiguration: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.playersTableView.dequeueReusableCell(withIdentifier: "playerCell")
        if cell == nil
        {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "playerCell")
            if videoPlayerArray != nil && (videoPlayerArray?.count)! > indexPath.row
            {
                for playerObj in videoPlayerArray!
                {
                    if playerObj.keys.contains(indexPath.row)
                    {
                        let videoPlayerView: UIView = (playerObj[indexPath.row]?.getVideoPlayerView())!
                        videoPlayerView.frame = CGRect.init(x: 10, y: 10, width: UIScreen.main.bounds.width - 20, height: (UIScreen.main.bounds.width - 20) * 9/16)
                        if cell?.contentView != nil {
                            cell?.contentView.addSubview(videoPlayerView)
                        }
                        else {
                            cell?.addSubview(videoPlayerView)
                        }
                    }
                }
            }
            else
            {
                let loaderView = self.addLoaderView(cellView: cell!)
                loaderView.startAnimating()
            
                let featureSupported = getPlayerFeaturesSupported()
                let vlBaseUrl = self.videoList.apiBaseUrl
                let vlBeaconURL: String? = self.videoList.beaconBaseUrl
                let vlToken = isGuestUser ? self.videoList.vlGuestToken : self.videoList.vlToken
                var vlPlayer: VLPlayer!

                let videoPlayerControlsView = self.enableCustomPlayerUI ? self.getCustomControls() : nil
                if playerOptionSelected == .playStreamURL || playerOptionSelected == .playASATURL{
                    let playerLicenseKey: String? = ""
                    let analyticsLicenseKey: String? = ""
                    let userId: String? = nil
                    if let playerLicenseKey = playerLicenseKey, !playerLicenseKey.isEmpty {
                        vlPlayer = VLPlayer(playerType: .bitmovin(config: VLBitmovinConfig(license: VLBitmovinConfig.VLBitmovinLicenseConfig(playerKey: playerLicenseKey, analyticsKey: analyticsLicenseKey), userId: userId)))
                    }else{
                        vlPlayer = VLPlayer.init()
                    }
                    videoPlayerControlsView?.videoPlayer = vlPlayer
                    vlPlayer.videoPlayerDelegate = self
                    vlPlayer.clientSideAdTrackingDelegate = self
                    vlPlayer.enablePlayerBitrateLogs = self.enableBitrateLogs
                    let isDVREnabled = self.streamConfig?.isDVR ?? false
                    vlPlayer.setSource(type: .directStream(VLPlayer.DirectStreamPlaybackConfig(stream: VLPlayer.DirectStreamType(url: streamUrl ?? "", contentId: nil,streamConfig: self.streamConfig, drmconfig: drmConfig), token: vlToken, apiBaseURL: vlBaseUrl)),customControlsView: videoPlayerControlsView, playerFeaturesSupported: featureSupported) { [weak self] isSuccess, playerView, contentResponse in
                        DispatchQueue.main.async {
                            loaderView.stopAnimating()
                            if let cell = cell, let playerView = playerView {
                                if isDVREnabled {
                                    videoPlayerControlsView?.updateControlsBasedOnDVRFlag(isDVREnabled: isDVREnabled)
                                }
                                self?.addPlayer(indexPath: indexPath, cell: cell, videoPlayerControlsView: videoPlayerControlsView, playerView: playerView, vlPlayer: vlPlayer)
                                
                            }
                        }
                    }

                }else{
                    vlPlayer = VLPlayer(playerType: .default)
                    vlPlayer.videoPlayerDelegate = self
                    vlPlayer.clientSideAdTrackingDelegate = self
                    vlPlayer.enablePlayerBitrateLogs = self.enableBitrateLogs
                    videoPlayerControlsView?.videoPlayer = vlPlayer
                    if let entitlementData{
                        vlPlayer.setEntitlement(data: entitlementData)
                    }
                    vlPlayer.setSource(type: .contentPlayback(VLPlayer.ContentPlaybackConfig(videoId: self.videoList.videoId, token: vlToken, apiBaseURL: vlBaseUrl)),customControlsView: videoPlayerControlsView, playerFeaturesSupported: featureSupported) { [weak self] isSuccess, playerView, contentResponse in
                        DispatchQueue.main.async {
                            loaderView.stopAnimating()
                            if let cell = cell, let playerView = playerView {
                                self?.addPlayer(indexPath: indexPath, cell: cell, videoPlayerControlsView: videoPlayerControlsView, playerView: playerView, vlPlayer: vlPlayer)
                                
                            }
                        }
                    }
                }
              
            }
        }
        else
        {
            for playerObj in videoPlayerArray!
            {
                if playerObj.keys.contains(indexPath.row)
                {
                    let videoPlayerView: UIView = (playerObj[indexPath.row]?.getVideoPlayerView())!
                    videoPlayerView.frame = CGRect.init(x: 10, y: 10, width: UIScreen.main.bounds.width - 20, height: (UIScreen.main.bounds.width - 20) * 9/16)
                    if cell?.contentView != nil {
                        cell?.contentView.addSubview(videoPlayerView)
                    }
                    else {
                        cell?.addSubview(videoPlayerView)
                    }
                }
            }
        }
        cell?.selectionStyle = .none
        return cell!
    }
    
    private func addPlayer(indexPath: IndexPath, cell: UITableViewCell, videoPlayerControlsView: CustomVideoControls?, playerView: UIView, vlPlayer: VLPlayer){
        if self.enableCustomPlayerUI {
            videoPlayerControlsView?.setupPictureInPicture()
            videoPlayerControlsView?.startPictureInPictureInline(enable: true)
            videoPlayerControlsView?.updatePlayerControlsType(playerControlType: vlPlayer.isLiveVideo() ? .liveVideoControls : .streamVideoControls)
            self.videoPlayerControlsArray?.append([indexPath.row: videoPlayerControlsView!])
        }
        playerView.frame = CGRect.init(x: 10, y: 10, width: UIScreen.main.bounds.width - 20, height: (UIScreen.main.bounds.width - 20) * 9/16)
        cell.contentView.addSubview(playerView)
        
        self.videoPlayerArray?.append([indexPath.row: vlPlayer])
        self.indexPathArray?.append(indexPath)
    }
    
    private func getCustomControls() -> CustomVideoControls{
        let videoPlayerControlsView = CustomVideoControls.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width - 20, height: (UIScreen.main.bounds.width - 20) * 9/16))
        if self.playerOptionSelected == .customControlWithCustomSeekDuration {
            videoPlayerControlsView.seekBackwardDuration = self.seekBackwardDuration
            videoPlayerControlsView.seekForwardDuration = self.seekForwardDuration
        }
        return videoPlayerControlsView
    }

    
    func showAlert(title: String = "Alert!", message: String = "Description") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (( UIScreen.main.bounds.width - 20) * 9/16) + 20
    }
    
    private func addLoaderView(cellView:UITableViewCell) -> UIActivityIndicatorView {
        var loadingIndicatorView:UIActivityIndicatorView?
        if #available(iOS 13.0, *) {
            loadingIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
            loadingIndicatorView?.color = .black
        }
        else {
            loadingIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
        }
        cellView.contentView.addSubview(loadingIndicatorView!)
        loadingIndicatorView?.frame.origin = CGPoint.init(x: (UIScreen.main.bounds.width - 20)/2, y: ((UIScreen.main.bounds.width - 20) * 9/16)/2)
        loadingIndicatorView?.hidesWhenStopped = true
        return loadingIndicatorView!
    }
    
    func additionalTrackingDetailsForClientSideAdTracking() -> [String : Any]? {
        ///Remark: For Nonce key name to be palNonce and then value for same
        return ["hello":"value"]
    }
    
    func initalisationForExternalAdTrackingSdk(playerView: UIView, playerSize: CGSize, completion: (() -> Void)) {
        completion()
    }
    
    func clientSideAdTrackingEvents(trackingEventType: VLPlayerLib.VLPlayer.AdsEventType, eventTrackingProperties: [String : Any]) {
        
    }
    
    //MARK: Video Player Delegates
    func videoStarted(timestamp: Double, playerTag: String) {
        guard let playerTag = Int(playerTag) else { return }
        let playerIndex: Int = (playerTag > 0) ? (playerTag - 1) : 0
        for playerObj in videoPlayerArray!
        {
            if playerObj.keys.contains(playerIndex)
            {
                if let playerObject = playerObj[playerIndex] {
                    if let playerControlsArray = self.videoPlayerControlsArray, playerControlsArray.count > 0, let videoPlayerControl = playerControlsArray[playerIndex][playerIndex] {
                        videoPlayerControl.updatePlayerControlsType(playerControlType: playerObject.isLiveVideo() ? .liveVideoControls : .streamVideoControls)
                        self.videoPlayerControlsArray?.remove(at: playerIndex)
                        self.videoPlayerControlsArray?.insert([playerIndex:videoPlayerControl], at: playerIndex)
                    }
                    playerObject.getVideoPlayerView()?.removeFromSuperview()
                    playerObject.videoPlayerDelegate = self
                    playerObject.getVideoPlayerView()?.frame = CGRect.init(x: 10, y: 10, width: UIScreen.main.bounds.width - 20, height: (UIScreen.main.bounds.width - 20) * 9/16)
                    
                    for indexPath in self.indexPathArray!
                    {
                        if indexPath.row == playerIndex
                        {
                            self.playersTableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    }
                    break
                }
            }
        }
        if videoPlayerControlsArray != nil
        {
            for playerControl in videoPlayerControlsArray!
            {
                if playerControl.keys.contains(playerIndex)
                {
                    playerControl[playerIndex]?.setPlayButtonState(state: true)
                    playerControl[playerIndex]?.updateTimeLabelOnStart()
                    break
                }
            }
        }
    }
    
    func videoPause(timestamp: Double, playerTag: String) {
        guard let playerTag = Int(playerTag) else { return }
        let playerIndex: Int = (playerTag > 0) ? (playerTag - 1) : 0
        if videoPlayerControlsArray != nil
        {
            for playerControl in videoPlayerControlsArray!
            {
                if playerControl.keys.contains(playerIndex)
                {
                    playerControl[playerIndex]?.setPlayButtonState(state: false)
                    break
                }
            }
        }
    }
    
    func videoResume(timestamp: Double, playerTag: String) {
        guard let playerTag = Int(playerTag) else { return }
        let playerIndex: Int = (playerTag > 0) ? (playerTag - 1) : 0
        if videoPlayerControlsArray != nil
        {
            for playerControl in videoPlayerControlsArray!
            {
                if playerControl.keys.contains(playerIndex)
                {
                    playerControl[playerIndex]?.setPlayButtonState(state: true)
                    break
                }
            }
        }
    }
    
    func videoFinished(playerTag: String) {
        guard let playerTag = Int(playerTag) else { return }
        let playerIndex: Int = (playerTag > 0) ? (playerTag - 1) : 0
        if videoPlayerControlsArray != nil
        {
            for playerControl in videoPlayerControlsArray!
            {
                if playerControl.keys.contains(playerIndex)
                {
                    playerControl[playerIndex]?.setPlayButtonState(state: false)
                    break
                }
            }
        }
    }
    
    func videoPlaybackError(currentTime: Double, errorMessage: String, errorCode: String, playerTag: String) {
        guard let playerTag = Int(playerTag) else { return }
        let playerIndex: Int = (playerTag > 0) ? (playerTag - 1) : 0
        if videoPlayerControlsArray != nil
        {
            for playerControl in videoPlayerControlsArray!
            {
                if playerControl.keys.contains(playerIndex)
                {
                    playerControl[playerIndex]?.setPlayButtonState(state: false)
                    break
                }
            }
        }
        if !errorMessage.isEmpty{
                self.showAlert(message: errorMessage)
        }
    }
    
    func videoFetchError(error: VLError?, playerTag: String?, contentResponse: Dictionary<String, AnyObject>?) {
        let errorDescription =  "Is content playable - \(error?.isPlayable ?? false) \n" +
        "Content Fetched successfully - \(error?.isSuccess ?? false) \n" +
        "Error Code - \(error?.errorCode ?? "errorCode") \n" +
        "Error Message - \(error?.errorMessage ?? "errorMessage") \n" +
        "Error VL Code - \(error?.vl_errorCode ?? "errorVLCode")"
        
        print("Error VL:", errorDescription)
        print("VideoFetchError: contentResponse:", contentResponse)
        DispatchQueue.main.async {
            self.showAlert(message: errorDescription)
            self.customPaywallView?.update(error?.errorMessage ?? "Error occurred while fetching content")
        }
    }
    
    func onFullScreenChange(currentTime: Double, isFullScreen: Bool, playerTag: String)
    {
        guard let appDelegate: AppDelegate =  UIApplication.shared.delegate as? AppDelegate, let videoPlayerArray = videoPlayerArray else {return}
        appDelegate.isFullScreen = isFullScreen
        
        guard let playerTag = Int(playerTag) else {return}
        let playerIndex: Int = (playerTag > 0) ? (playerTag - 1) : 0
        
        if isFullScreen
        {
            
            for playerObj in videoPlayerArray
            {
                if playerObj.keys.contains(playerIndex)
                {
                    if let playerView = playerObj[playerIndex]?.getVideoPlayerView() {
                        playerView.removeFromSuperview()
                    }
                    fullScreenView = FullScreenPlayerViewController()
                    fullScreenView?.modalPresentationStyle = .fullScreen
                    fullScreenView?.view.frame = UIScreen.main.bounds
                    self.present(fullScreenView!, animated: false) {
                        guard let videoPlayerControlsArray = self.videoPlayerControlsArray else {return}
                        for playerControl in videoPlayerControlsArray
                        {
                            if playerControl.keys.contains(playerIndex)
                            {
                                playerControl[playerIndex]?.frame = (playerObj[playerIndex]?.getVideoPlayerView()?.frame)!
                                playerControl[playerIndex]?.updateControls(with: .full)
                                playerObj[playerIndex]?.setPlayerFitToFullScreen()
                                break
                            }
                        }
                    }
                    if let playerView = playerObj[playerIndex]?.getVideoPlayerView() {
                        fullScreenView?.loadPlayerView(playerView: playerView)
                    }
                    break
                }
            }
        }
        else
        {
            for playerObj in videoPlayerArray
            {
                if playerObj.keys.contains(playerIndex)
                {
                    if self.fullScreenView != nil
                    {
//                        playerObj[playerIndex]?.getVideoPlayerView()?.removeFromSuperview()
//                        self.fullScreenView?.dismissPlayerView()
                        self.fullScreenView?.dismiss(animated: false, completion: {
//                            DispatchQueue.main.async {
                                for indexPath in self.indexPathArray!
                                {
                                    if indexPath.row == playerIndex
                                    {
                                        self.playersTableView.reloadRows(at: [indexPath], with: .automatic)
                                    }
                                    if self.videoPlayerControlsArray != nil
                                    {
                                        for playerControl in self.videoPlayerControlsArray!
                                        {
                                            if playerControl.keys.contains(playerIndex)
                                            {
                                                playerControl[playerIndex]?.frame = (playerObj[playerIndex]?.getVideoPlayerView()?.bounds)!
                                                playerControl[playerIndex]?.updateControls(with: .small)
                                                playerObj[playerIndex]?.setPlayerFitToSmallScreen(frame: .zero)
                                                break
                                            }
                                        }
                                    }
                                }
//                            }
                        })
                    }
                    break
                }
            }
        }
    }
    
    ///picture in picture delegates
    func pictureInPictureSetupCompleted(isPIPSelected: Bool) {
        print(#function)
    }
    
    func pictureInPictureWillStart() {
        print(#function)
    }
    
    func pictureInPictureDidStart() {
        print(#function)
        guard let _videoPlayerArray = self.videoPlayerArray,
              let playerDict = _videoPlayerArray.first else {return dismissViewController()}

        guard let vlPlayer = playerDict[0] else { return }
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
    
    ///Progress delegate
    func videoPlayerProgressByEverySecond(currentTime: Double, totalTime: Double, playerTag: String, parsedTimeStamp: String?) {
        let playerIndex: Int = Int(playerTag)! - 1
        guard let _videoPlayerControlsArray = self.videoPlayerControlsArray, let _videoPlayerArray = self.videoPlayerArray else {return}
        

        var elapsedTime = currentTime

        for player in _videoPlayerArray
        {
            if player.keys.contains(playerIndex)
            {
                if let startOverTime =  player[playerIndex]?.getStartOverTime() {
                    if currentTime > totalTime{
                        elapsedTime = totalTime
                    }
                }
             
                break
            }
        }
        for playerControl in _videoPlayerControlsArray
        {
            if playerControl.keys.contains(playerIndex)
            {
                playerControl[playerIndex]?.updateTimeLabel(timeRemaining: (totalTime - currentTime), elapsedTime: currentTime)
                playerControl[playerIndex]?.updateSliderDuration(sliderValue: self.getSliderDuration(currentTime: elapsedTime, totalDuration: totalTime))
                break
            }
        }
    }
    
    func getSliderDuration(currentTime: Double, totalDuration: Double) -> Double {
        guard totalDuration > 0, currentTime <= totalDuration else {return 0}
        return Double(currentTime/totalDuration)
    }
    
    ///Player bitrate logs
    func playerBitrateDebugLogs(logString: String) {
        debugLogView.isHidden = !enableBitrateLogs
        if enableBitrateLogs {
            debugLogView.text.append(logString)
            let range = NSMakeRange(debugLogView.text.count - 1, 0)
            debugLogView.scrollRangeToVisible(range)
            debugLogView.text.append("\n\n")
        }
    }
    
    //MARK: Full screen player controller delegates
    func fullScreenViewRemoved(playerTag: String)
    {
        let playerIndex: Int = Int(playerTag)! - 1
        for playerObj in videoPlayerArray!
        {
            if playerObj.keys.contains(playerIndex)
            {
                playerObj[playerIndex]?.getVideoPlayerView()?.removeFromSuperview()
                playerObj[playerIndex]?.videoPlayerDelegate = self
                playerObj[playerIndex]?.getVideoPlayerView()?.frame = CGRect.init(x: 10, y: 10, width: UIScreen.main.bounds.width - 20, height: (UIScreen.main.bounds.width - 20) * 9/16)
                
                for indexPath in self.indexPathArray!
                {
                    if indexPath.row == playerIndex
                    {
                        self.playersTableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                }
                break
            }
        }
    }
    
    func loginWithTVE() {
        debugPrint("Login with TVE called")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    @IBAction func addNextVideo(sender: Any)
    {
        if !nextVideoLists.isEmpty {
            guard let _videoPlayerArray = self.videoPlayerArray else {return}
            let playerIndex = 0
            
            let nextPlayableVideo = nextVideoLists.removeFirst()
            for playerObj in _videoPlayerArray
            {
                if playerObj.keys.contains(playerIndex)
                {
                    playerObj[playerIndex]?.setNextVideo(videoId: nextPlayableVideo, adTag: nil)
                    addedNextVideoList.append(nextPlayableVideo)
                    break
                }
            }
        }
        else {
            let alertController = UIAlertController(title: "Alert!", message: "No more video to be added in queue", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func playNextVideo(sender: Any)
    {
        guard let _videoPlayerArray = self.videoPlayerArray else {return}
        let playerIndex = 0
        
        for playerObj in _videoPlayerArray
        {
            if playerObj.keys.contains(playerIndex)
            {
                if let playerObject = playerObj[playerIndex] {
                    if let playerControlsArray = self.videoPlayerControlsArray, playerControlsArray.count > 0, let videoPlayerControl = playerControlsArray[playerIndex][playerIndex] {
                        videoPlayerControl.updateTimeLabel(timeRemaining: 0, elapsedTime: 0)
                        self.videoPlayerControlsArray?.remove(at: playerIndex)
                        self.videoPlayerControlsArray?.insert([playerIndex:videoPlayerControl], at: playerIndex)
                    }
                    
                    playerObject.playNextVideo(videoId: nil, vlToken: nil, adTag: nil){ [weak self] (success) in
                        
                    }
                    
                    addedNextVideoList.removeFirst()
                    break
                }
            }
        }
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        guard let _videoPlayerArray = self.videoPlayerArray,
              let playerDict = _videoPlayerArray.first else {return dismissViewController()}
        
        let vlPlayer = playerDict[0]
        vlPlayer?.destroy()
        dismissViewController()
    }
    
    private func dismissViewController() {
        self.dismiss(animated: true, completion: nil)
    }
    func chromeCastConnectionStatusUpdate(isConnected:Bool) {
        print("Cast connected>>>", isConnected)
    }
    
    func getChromeCastConnectedStatus() {
        guard let _videoPlayerArray = self.videoPlayerArray,
              let playerDict = _videoPlayerArray.first else {return}
        
        let vlPlayer = playerDict[0]
        print("Cast connected>>>", vlPlayer?.getChromeCastConnectedStatus())
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
//        guard let videoPlayerControlsArray = self.videoPlayerControlsArray,
//              !videoPlayerControlsArray.isEmpty
//        else { return }
        
        coordinator.animate(alongsideTransition: { _ in
            if size.width > size.height {
                // Update for landscape
                if (UIApplication.shared.delegate as? AppDelegate)?.isFullScreen == false {
                    let player = self.videoPlayerArray?.first?[0]
                    player?.goFullScreen()
                }
            } else {
                // Update for portrait
                if (UIApplication.shared.delegate as? AppDelegate)?.isFullScreen == true {
                    let player = self.videoPlayerArray?.first?[0]
                    player?.goFullScreen()
                }
            }
        }, completion: nil)
        
       
        
    }
}



