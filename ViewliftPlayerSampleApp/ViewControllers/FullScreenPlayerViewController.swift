//
//  FullScreenPlayerViewController.swift
//  ViewliftPlayerSampleApp
//
//  Created by Abhinav Saldi on 09/07/18.
//  Copyright © 2018 Viewlift. All rights reserved.
//

import UIKit
import VLPlayerLib

@objc protocol FullScreenDelegate: NSObjectProtocol {
    @objc func fullScreenViewRemoved(playerTag: String)
}

class FullScreenPlayerViewController: UIViewController {

    var playerFullScreenView: UIView?
    var delegate: FullScreenDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isStatusBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super .viewWillDisappear(animated)
        UIApplication.shared.isStatusBarHidden = false
    }

    func loadPlayerView(playerView:UIView) {
        playerView.translatesAutoresizingMaskIntoConstraints = true
        playerFullScreenView = playerView
        playerFullScreenView?.frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        self.view.addSubview(playerFullScreenView!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override var prefersStatusBarHidden: Bool {
        
        return true
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
