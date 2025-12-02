//
//  ViewController.swift
//  TestSDK
//
//  Created by Gaurav Vig on 30/04/18.
//  Copyright © 2018 Viewlift. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak private var multiplePlayerOptionTable: UITableView!
    @IBOutlet weak private var autoPlayToggle: UISwitch!
    @IBOutlet weak private var loopPlaybackToggle: UISwitch!
    @IBOutlet weak private var hideControls: UISwitch!
    @IBOutlet weak private var muteControls: UISwitch!
    private var playerOptionSelected:PlayerUIOptions = .defaultControl
    private var playerUIOptions: [PlayerUIOptions] = [.exploreMore]
    
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
        }else{
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
