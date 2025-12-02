//
//  ViewController.swift
//  TestSDK
//
//  Created by Gaurav Vig on 30/04/18.
//  Copyright © 2018 Viewlift. All rights reserved.
//

import UIKit
import VLPlayerLib

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak private var multiplePlayerOptionTable: UITableView!
    @IBOutlet weak private var autoPlayToggle: UISwitch!
    @IBOutlet weak private var loopPlaybackToggle: UISwitch!
    @IBOutlet weak private var hideControls: UISwitch!
    @IBOutlet weak private var muteControls: UISwitch!
    private var playerOptionSelected:PlayerUIOptions = .defaultControl
    private var playerUIOptions: [PlayerUIOptions] = [.exploreMore, .verticalPlayer]
    let vm = FeedVCVM()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        multiplePlayerOptionTable.reloadData()
        // Do any additional setup after loading the view, typically from a nib.
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let videoList = AppDelegate.shared.readVideoListOperation?.videoList else{
            return
        }
        let xApiKey: String = videoList.xApiKey
        let siteId: String = videoList.authKeys.siteId
        let apiBaseEndpoint: String = videoList.authKeys.apiBaseEndpoint
        
        self.showAlertIfConfigInvalid(apiBaseEndpoint: apiBaseEndpoint,
                                      authorizationToken: AppDelegate.shared.authorizationToken,
                                      siteId: siteId,
                                      xApiKey: xApiKey,
                                      alertMessage: "Detected invalid configuration! Please update your settings.")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    //TableViewMethods
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "MultiplePlayerUICell", for: indexPath)
        let textLabel = tableCell.contentView.viewWithTag(111) as? UILabel
        textLabel?.text = playerUIOptions[indexPath.row].rawValue
        return tableCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playerUIOptions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        playerOptionSelected = playerUIOptions[indexPath.row]
        
        if playerOptionSelected == .exploreMore{
            guard let _videoList = AppDelegate.shared.readVideoListOperation?.videoList else {return}
            let assetVC = AssetListViewController()
            assetVC.videoList = _videoList
            navigationController?.pushViewController(assetVC, animated: true)
        } else if playerOptionSelected == .verticalPlayer {
            
            let verticalVC = VLFeedPlayer().setSource(delegate: vm,
                                                      config: vm.config,
                                                      baseUrl: vm.baseUrl,
                                                      authToken: vm.authToken)!
            navigationController?.pushViewController(verticalVC, animated: true)
            navigationController?.setNavigationBarHidden(false, animated: true)
            
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
            navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
            
            navigationController?.navigationBar.isTranslucent = true
            
        } else{
            launchVideoPlayer()
        }
    }
    
    func showAlert(title: String = "Alert!", message: String = "Description") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Player UI Options"
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    ///Private methods
    private func launchVideoPlayer() {
        guard let _videoList = AppDelegate.shared.readVideoListOperation?.videoList else {return}
        if let message = _videoList.checkForConfigurationErrorMessage() {
            showAlert(message: message)
            return
        }
        if _videoList.videoId.contains("xxxxx"){
            showAlert(title: "Alert!", message: "Please update the videoId in configs.json file to play the video.")
            return
        }
            
        let videoPlaybackController = self.storyboard?.instantiateViewController(withIdentifier: "PlayerViewController_iOS") as! PlayerViewController_iOS
//        videoPlaybackController.view.frame = self.view.bounds
        if playerOptionSelected == .playStreamURL || playerOptionSelected == .playASATURL {
            videoPlaybackController.streamUrl =  _videoList.streamUrl
        }
        videoPlaybackController.channelId = _videoList.channelId
        videoPlaybackController.autoplayEnabled = self.autoPlayToggle.isOn
        videoPlaybackController.loopEnabled = self.loopPlaybackToggle.isOn
        videoPlaybackController.hideControls = self.hideControls.isOn
        videoPlaybackController.muteEnabled = self.muteControls.isOn
        videoPlaybackController.prepareView(withPlayerUIOption: playerOptionSelected, videoList: _videoList)
        videoPlaybackController.modalPresentationStyle = .fullScreen
        self.present(videoPlaybackController, animated: true, completion: nil)
    }
    @IBAction func valueChangeForToggle(sender: UISwitch){
        
    }
}

class FeedVCVM: FeedViewDelegate {
    
    deinit {
        debugPrint("----------> FeedVCVM: Deinit")
    }
    
    let baseUrl = "https://livgolfplus.staging.api.viewlift.com"
    let authToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzaXRlIjoibGl2LWdvbGYiLCJzaXRlSWQiOiI5ZWQ3ZGVlMC1jNzE5LTExZWMtYmMyNS1hMTk1YzJhMzQzNTciLCJpZCI6IjU3N2M1ZDhjLWNkNGItNDQ3YS1hMzJkLTkwNTNmZGZiZTQyNyIsInVzZXJJZCI6IjU3N2M1ZDhjLWNkNGItNDQ3YS1hMzJkLTkwNTNmZGZiZTQyNyIsImlwYWRkcmVzc2VzIjoiMTIyLjE2Mi4xNDguMTM3IiwiY291bnRyeUNvZGUiOiJJTiIsInBvc3RhbGNvZGUiOiIxMTAwNDMiLCJwcm92aWRlciI6InZpZXdsaWZ0IiwiZGV2aWNlSWQiOiJicm93c2VyLTYwYjBhNzI2LTI5MzctNDEwNC1lZjdkLTYyODc5NWRlNDdiZSIsImVtYWlsIjoiamFwbmVldHNpbmdoQHZpZXdsaWZ0LmNvbSIsImlhdCI6MTc2NDA4OTE0OCwiZXhwIjoxNzY0NjkzOTQ4fQ.AbhI-J89ArvU3zhltA7WLJeS10B0LrebSI0vA_86KUU"
    
    var idsURL1 : [String] {
        let urlStream1 = "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"
        let urlStream2 = "https://vz-cea98c59-23c.b-cdn.net/c309129c-27b6-4e43-8254-62a15c77c5ee/842x480/video.m3u8"
        let urlStream3 = "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"
        
        return [urlStream1, urlStream2, urlStream3]
    }
    
    var idsURL2 : [String] {
        let urlStream4 = "https://test-streams.mux.dev/test_001/stream.m3u8"
        let urlStream5 = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        return [urlStream4, urlStream5 ]
    }
    
    let id1 = ["2f872a0a-2baa-420f-a712-b182e9f0aea2",
               "0e081c22-0c54-45ea-8d3f-3481fc6dd22c",
               "71734d24-f644-43f8-ad56-5ad383323527"]
    
    
    let id2 = ["77dea7e5-57ab-426f-8703-0975dd36b509",
               "bd692bb9-c09c-4ccb-9350-74664d9b3250",
    ]
    
    var staticId : [String] {  // urls + ids
        idsURL1 + id1 + idsURL2 + id1 + id1 + idsURL1 + id1 + id1
    }
    
    let adMap: [Int: String] = [ //index : ad image
        2 : "https://images.livgolf.com/image/private/t_ratio1_1-size40-f_webp-c_fill/v1755467742/prd/qmesld7wkfujgglizptp",
        5 : "https://images.livgolf.com/image/private/t_ratio1_1-size40-f_webp-c_fill/v1755722617/prd/tcbep6b3g7hhb6xmxb95",
        8 : "https://images.livgolf.com/image/private/t_ratio1_1-size40-f_webp-c_fill/v1759107042/prd/qxf82i9zlgkbs23hevu6",
        11: "https://images.livgolf.com/image/private/t_ratio1_1-size40-f_webp-c_fill/prd/zpj35lw9zviagwioid3l",
        14: "https://images.livgolf.com/image/private/t_ratio1_1-size40-f_webp-c_fill/v1755522988/prd/shdbleeh3cgwlqb8svuu",
        17: "https://images.livgolf.com/image/private/t_ratio1_1-size40-f_webp-c_fill/prd/al3bx1cojlfqfjdlorgv",
        20: "https://images.livgolf.com/image/private/t_ratio1_1-size40-f_webp-c_fill/prd/ugt8i6c2ck6tqbbqpete"
    ]
    
    var config: FeedViewConfig {
        FeedViewConfig(
            items: staticId,
            adImageMap: adMap,
            autoSwipe: true,
            maxFeedPlayer: 6
        )
    }
    
    func currentImageAd(imageUrl: String) {
        print("****** FeedViewDelegate: currentImageAd: \(imageUrl)")
    }
    
    func currentFeedPlaying(videoID: String) {
        print("****** FeedViewDelegate: currentFeedPlaying: \(videoID)")
    }
    
    func feedPlayerStatus(isPlaying: Bool) {
        print("****** FeedViewDelegate: feedPlayerStatus \(isPlaying)")
    }
    
    func userFeedInteraction(type: VLPlayerLib.FeedInteraction, videoID: String) {
        print("****** FeedViewDelegate: userFeedInteraction \(type): videoID: \(videoID)")
    }
}
