//
//  ViewController.swift
//  TestSDK
//
//  Created by Gaurav Vig on 30/04/18.
//  Copyright © 2018 Viewlift. All rights reserved.
//

import UIKit

protocol VideoListProtocol {
    var videoList:VideoList? {get set}
    func readVideoList()
}

enum PlayerUIOptions: Int {
    case defaultControl = 0
    case customControl
    case debugLogEnabled
    case customControlWithDebugLog
    case customControlWithCustomSeekDuration
    case adsEnabled
    case playStreamURL
    case playASATURL
    case exploreMore
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak private var multiplePlayerOptionTable: UITableView!
    @IBOutlet weak private var autoPlayToggle: UISwitch!
    @IBOutlet weak private var loopPlaybackToggle: UISwitch!
    @IBOutlet weak private var hideControls: UISwitch!
    @IBOutlet weak private var muteControls: UISwitch!
    private var readVideoListOperation:VideoListProtocol?
    private var playerOptionSelected:PlayerUIOptions = .defaultControl
    private var playerUIOptions = ["Default sdk controls", "Custom controls", "Debug logs enabled", "Custom controls and debug logs enabled", "Custom controls and custom seek duration", "Ads Enabled", "Play Stream URL", "Play ASAT URL", "Explore More"]
    
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
        textLabel?.text = playerUIOptions[indexPath.row]
        return tableCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playerUIOptions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        playerOptionSelected = PlayerUIOptions(rawValue: indexPath.row) ?? .defaultControl
        if playerOptionSelected == .exploreMore{
            guard let _videoList = self.readVideoListOperation?.videoList else {return}
            let assetVC = AssetListViewController()
            assetVC.videoList = _videoList
            navigationController?.pushViewController(assetVC, animated: true)
        }else{
            launchVideoPlayer()
        }
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
        let videoPlaybackController = self.storyboard?.instantiateViewController(withIdentifier: "VideoPlaybackController") as! VideoPlaybackController
        videoPlaybackController.view.frame = self.view.bounds
        if playerOptionSelected == .playStreamURL || playerOptionSelected == .playASATURL {
            videoPlaybackController.streamUrl =  _videoList.streamUrl
        }
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


class ReadFromLocalJson:VideoListProtocol {
    var videoList: VideoList?
    
    func readVideoList() {
        if let path = Bundle.main.path(forResource: "VideoList", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                self.videoList = try JSONDecoder().decode(VideoList.self, from: data)
            } catch {
                // handle error
            }
        }
    }
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
