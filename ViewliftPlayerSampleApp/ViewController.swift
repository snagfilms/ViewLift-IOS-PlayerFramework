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
    #if os(iOS)
    @IBOutlet weak private var autoPlayToggle: UISwitch!
    @IBOutlet weak private var loopPlaybackToggle: UISwitch!
    @IBOutlet weak private var hideControls: UISwitch!
    @IBOutlet weak private var muteControls: UISwitch!
    #endif
    private var readVideoListOperation:VideoListProtocol?
    private var playerOptionSelected:PlayerUIOptions = .defaultControl
    private var playerUIOptions: [PlayerUIOptions] = [.exploreMore, .defaultControl, .customControl]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        readVideoList(readVideoListOperation: ReadFromLocalJson())
//        readVideoList(readVideoListOperation: ReadFromAPI())
        multiplePlayerOptionTable.reloadData()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func readVideoList(readVideoListOperation: VideoListProtocol) {
        self.readVideoListOperation = readVideoListOperation
        self.readVideoListOperation?.readVideoList()
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
            guard let _videoList = self.readVideoListOperation?.videoList else {return}
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
        guard let _videoList = self.readVideoListOperation?.videoList else {return}
        if let message = _videoList.checkForConfigurationErrorMessage() {
            showAlert(message: message)
            return
        }
        if _videoList.videoId.contains("xxxxx"){
            showAlert(title: "Alert!", message: "Please update the videoId in VideoList.json file to play the video.")
            return
        }
            
        let videoPlaybackController = self.storyboard?.instantiateViewController(withIdentifier: "VideoPlaybackController") as! VideoPlaybackController
        videoPlaybackController.view.frame = self.view.bounds
        if playerOptionSelected == .playStreamURL || playerOptionSelected == .playASATURL {
            videoPlaybackController.streamUrl =  _videoList.streamUrl
        }
        #if os(iOS)
        videoPlaybackController.autoplayEnabled = self.autoPlayToggle.isOn
        videoPlaybackController.loopEnabled = self.loopPlaybackToggle.isOn
        videoPlaybackController.hideControls = self.hideControls.isOn
        videoPlaybackController.muteEnabled = self.muteControls.isOn
        #endif
        videoPlaybackController.prepareView(withPlayerUIOption: playerOptionSelected, videoList: _videoList)
        videoPlaybackController.modalPresentationStyle = .fullScreen
        self.present(videoPlaybackController, animated: true, completion: nil)
    }
    #if os(iOS)
    @IBAction func valueChangeForToggle(sender: UISwitch){
        
    }
    #endif
}

class ReadFromAPI:VideoListProtocol {
    var videoList: VideoList?
    
    func readVideoList() {
        NetworkHandler.sharedInstance.fetchDataFromAPI { responseConfigData, responseErrorData, isSuccess in
            if responseConfigData != nil {
                do {
                    self.videoList = try JSONDecoder().decode(VideoList.self, from: responseConfigData!)
                } catch {
                    // handle error
                }
            }
        }
    }
}
