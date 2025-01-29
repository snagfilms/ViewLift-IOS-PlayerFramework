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

    @IBOutlet var playersTableView:UITableView!
    @IBOutlet var debugLogView:UITextView!
    @IBOutlet weak var addNextButton: UIButton!
    @IBOutlet weak var playNextButton: UIButton!
    private var videoList:VideoList!
    private var enableCustomPlayerUI:Bool! = false
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
    
    var loopEnabled: Bool = false
    var autoplayEnabled: Bool = true
    var hideControls: Bool = false
    var muteEnabled: Bool = false
    
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
        
        return VLPlayer.VLPlayerFeatureSupported(fullScreenOnly: false,
                                                 isCustomLoaderAdded: false,
                                                 shouldStartPictureInPictureInline: true,
                                                 autoPlayEnabled: true,
                                                 loopVideoPlayback: self.loopEnabled,
                                                 hideVideoControls: self.hideControls,
                                                 mutePlayback: self.muteEnabled,
                                                 customPlayerControlsColor: nil,
                                                 clientSideAdTrackingDetails: VLPlayer.VLClientSideAdTrackingDetails.init(isClientSideAdTrackingEnabled: true, isWTAEnabled: true), showPlayerControlAlways: false,
                                                 supportsChromeCast: true,
                                                 chromecastCustomReceiver: nil,
                                                 playerResponseRequired:true,
                                                 preGameStartTime: nil,
                                                 appMacrosList: nil, vlBeacon: VLBeacon.getInstance())
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
                let vlBaseUrl = ""
                let vlToken = self.videoList.playbackToken
                let streamURL = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                var vlPlayer: VLPlayer!
                if playerOptionSelected == .playStreamURL {
                    enableCustomPlayerUI = true
                    let playerLicenseKey = ""
                    let analyticsLicenseKey = ""
                    if playerLicenseKey.isEmpty || analyticsLicenseKey.isEmpty {
                        vlPlayer = VLPlayer.init()
                    } else {
                        vlPlayer = VLPlayer(playerType: .bitmovin(config: VLBitmovinConfig(license: VLBitmovinConfig.VLBitmovinLicenseConfig(playerKey: playerLicenseKey, analyticsKey: analyticsLicenseKey), userId: nil)))
                    }
                    vlPlayer.videoPlayerDelegate = self
                    vlPlayer.clientSideAdTrackingDelegate = self
                    vlPlayer.enablePlayerBitrateLogs = self.enableBitrateLogs
                    
                    //MARK: isASATPlayer bool is required to check monetisation
                    vlPlayer.setSourceToPlay(isASATPlayer: true, streamURL: streamURL, vlToken: vlToken, vlAPIEndPoint: vlBaseUrl, vlBeaconEndPoint: nil, customControlsView: nil, playerFeaturesSupported: featureSupported){ status, playerView in
                        DispatchQueue.main.async { [weak self] in
                            guard let checkedSelf = self else {return}
                            loaderView.stopAnimating()
                            
                            guard status else { return }
                            
                            playerView?.frame = CGRect.init(x: 10, y: 10, width: UIScreen.main.bounds.width - 20, height: (UIScreen.main.bounds.width - 20) * 9/16)
                            if cell?.contentView != nil {
                                cell?.contentView.addSubview(playerView!)
                            }
                            else {
                                cell?.addSubview(playerView!)
                            }
                            checkedSelf.videoPlayerArray?.append([indexPath.row: vlPlayer])
                            checkedSelf.indexPathArray?.append(indexPath)
                        }
                    }
                }else{
                    vlPlayer =  VLPlayer(playerType: .default)
                    vlPlayer.videoPlayerDelegate = self
                    vlPlayer.clientSideAdTrackingDelegate = self
                
                    ///Code for custom controls
                    var videoPlayerControlsView: CustomVideoControls?
                    if self.enableCustomPlayerUI {
                        videoPlayerControlsView = CustomVideoControls.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width - 20, height: (UIScreen.main.bounds.width - 20) * 9/16))
                        if self.playerOptionSelected == .customControlWithCustomSeekDuration {
                            videoPlayerControlsView?.seekBackwardDuration = self.seekBackwardDuration
                            videoPlayerControlsView?.seekForwardDuration = self.seekForwardDuration
                        }
                        videoPlayerControlsView?.videoPlayer = vlPlayer
                    }
                    vlPlayer.enablePlayerBitrateLogs = self.enableBitrateLogs
                    

                    vlPlayer.setSource(vlToken: vlToken, vlAPIEndPoint: vlBaseUrl, videoID: self.videoList.videoId, vlPlayerTag: "\(indexPath.row + 1)", customControlsView: videoPlayerControlsView, adUrl: self.adUrl, playerProgressInterval: 1, playerFeaturesSupported: featureSupported, tveProvider: nil, location: nil) { [weak self] (success, playerView, playerResoponse)  in
                        guard let checkedSelf = self else {return}
                        DispatchQueue.main.async {
                            loaderView.stopAnimating()
                            if success
                            {
                                if checkedSelf.enableCustomPlayerUI {
                                    videoPlayerControlsView?.setupPictureInPicture()
                                    videoPlayerControlsView?.startPictureInPictureInline(enable: true)
                                    videoPlayerControlsView?.updatePlayerControlsType(playerControlType: vlPlayer.isLiveVideo() ? .liveVideoControls : .streamVideoControls)
                                    checkedSelf.videoPlayerControlsArray?.append([indexPath.row: videoPlayerControlsView!])
                                }
                                playerView?.frame = CGRect.init(x: 10, y: 10, width: UIScreen.main.bounds.width - 20, height: (UIScreen.main.bounds.width - 20) * 9/16)
                                if cell?.contentView != nil {
                                    cell?.contentView.addSubview(playerView!)
                                }
                                else {
                                    cell?.addSubview(playerView!)
                                }
                                checkedSelf.videoPlayerArray?.append([indexPath.row: vlPlayer])
                                checkedSelf.indexPathArray?.append(indexPath)
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
        let playerIndex: Int = Int(playerTag)! - 1
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
        let playerIndex: Int = Int(playerTag)! - 1
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
        let playerIndex: Int = Int(playerTag)! - 1
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
        let playerIndex: Int = Int(playerTag)! - 1
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
        let playerIndex: Int = Int(playerTag)! - 1
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
    
    func videoFetchError(error: VLError?, playerTag: String?, contentResponse: Dictionary<String, AnyObject>?) {
        let errorDescription =  "Is content playable - \(error?.isPlayable ?? false) \n" +
        "Content Fetched successfully - \(error?.isSuccess ?? false) \n" +
        "Error Code - \(error?.errorCode ?? "errorCode") \n" +
        "Error Message - \(error?.errorMessage ?? "errorMessage") \n" +
        "Error VL Code - \(error?.vl_errorCode ?? "errorVLCode")"
        
        print("Error VL:", errorDescription)
        print("VideoFetchError: contentResponse:", contentResponse)
        showAlert(message: errorDescription)
    }
    
    func onFullScreenChange(currentTime: Double, isFullScreen: Bool, playerTag: String)
    {
        guard let appDelegate: AppDelegate =  UIApplication.shared.delegate as? AppDelegate, let videoPlayerArray = videoPlayerArray else {return}
        appDelegate.isFullScreen = isFullScreen
        if isFullScreen
        {
            guard let playerTag = Int(playerTag) else {return}
            let playerIndex: Int = playerTag - 1
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
            let playerIndex: Int = Int(playerTag)! - 1
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
    func videoPlayerUpdateProgressby30Seconds(currentTime: Double, totalTime: Double, playerTag: String) {
        let playerIndex: Int = Int(playerTag)! - 1
        guard let _videoPlayerControlsArray = self.videoPlayerControlsArray else {return}
        for playerControl in _videoPlayerControlsArray
        {
            if playerControl.keys.contains(playerIndex)
            {
                playerControl[playerIndex]?.updateTimeLabel(timeRemaining: (totalTime - currentTime), elapsedTime: currentTime)
                break
            }
        }
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
    
//    func getMiniCastControllerView() {
//        guard let _videoPlayerArray = self.videoPlayerArray,
//              let playerDict = _videoPlayerArray.first else { return }
//        
//        let vlPlayer = playerDict[0]
//        if let view = vlPlayer?.getMiniCastControllerView(){
//            //Add mini view
//        }
//        
//    }
}
