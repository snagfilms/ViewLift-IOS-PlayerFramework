//
//  CustomVideoControls.swift
//  VLPlayer
//
//  Created by Abhinav Saldi on 08/06/18.
//  Copyright © 2018 Viewlift. All rights reserved.
//

import UIKit
import VLPlayerLib
import AVKit

class CustomVideoControls: UIView {
    
    enum PlayerControlScreen : String
    {
        case full
        case small
    }
    
    enum PlayerControlType : String
    {
        case liveVideoControls
        case streamVideoControls
    }
    private var chromecastButton: UIButton!
    private var backbutton: UIButton!
    private var playButton: UIButton!
    private var rewindButton: UIButton!
    private var forwardButton: UIButton!
    private var timeRemainingLabel: UILabel!
    private var currentTimeLabel: UILabel!
    private var fullScreenButton: UIButton!
    private var gradientView: UIView!
    private var isBackButtonTapped: Bool = false
    
    private let controlsHeight: CGFloat = 30
    private let timeLabelWidth: CGFloat = 70
    
    private var gradientLayer: CAGradientLayer!
    var videoPlayer: VLPlayer?
    private var playerControlScreen: PlayerControlScreen
    private var playerControlType: PlayerControlType
    private var pictureInPictureButton: UIButton!
    private var videoSeekSlider:UISlider!
    private var ccButton: UIButton!
    
    var seekForwardDuration:Double?
    var seekBackwardDuration:Double?
    private var zoomInOutButton: UIButton = {
        let _zoomInOutButton = UIButton(type: .custom)
        _zoomInOutButton.setImage(UIImage(named: "icon-zoomin"), for: .normal)
        _zoomInOutButton.setImage(UIImage(named: "icon-zoomout"), for: .selected)
        _zoomInOutButton.isHidden = false
        return _zoomInOutButton
    }()
    
    override init(frame: CGRect) {
        self.playerControlType = .streamVideoControls
        self.playerControlScreen = .small
        super.init(frame: frame)
        self.createView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewLoad() -> Void
    {
        var controlsY: CGFloat = self.bounds.size.height - controlsHeight - 5
        
        var leftPadding:CGFloat = 0.0
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            let bottomPadding = window?.safeAreaInsets.bottom
            leftPadding = window?.safeAreaInsets.left ?? 0
            controlsY -= (bottomPadding ?? 0)
        }
        self.playButton.frame = CGRect.init(x: 13 + leftPadding, y: controlsY + 3, width: 18.5, height: 21)
        self.rewindButton.frame = CGRect.init(x: self.playButton.frame.maxX + 13, y: controlsY, width: 26, height: 26)
        self.forwardButton.frame = CGRect.init(x: self.playButton.frame.maxX + 13, y: controlsY, width: 26, height: 26)
        self.zoomInOutButton.frame = CGRect(x: self.frame.width - 35, y: 0, width: 40, height: 40)
        self.chromecastButton.frame = CGRect.init(x:  self.frame.width - 80, y:  0, width: 30, height: 40)
        self.updateControls(with: .full)
    }
    
    private func createView() -> Void {
        
        self.fullScreenButton = UIButton(type: .custom)
        self.fullScreenButton.addTarget(self, action: #selector(fullScreenButtonTapped(sender:)), for: .touchUpInside)
        self.fullScreenButton.setImage(UIImage.init(named: "Fullscreen"), for: .normal)
        self.fullScreenButton.imageEdgeInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        self.addSubview(self.fullScreenButton)
        
        let castImage = UIImage(named: "ChromeCast_Normal_Off_iPad")
        let chromecastButtonImageView: UIImageView = UIImageView.init(image: castImage)
        self.chromecastButton = UIButton(type: .custom)
        self.chromecastButton.addTarget(self, action: #selector(castButtonTapped(sender:)), for: .touchUpInside)
        self.chromecastButton.setImage(chromecastButtonImageView.image?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.chromecastButton.imageView?.tintColor = .white
        self.addSubview(self.chromecastButton)
        
        self.playButton = UIButton.init(type: UIButton.ButtonType.custom)
        self.playButton.setImage(UIImage.init(named: "Pause"), for: .selected)
        self.playButton.setImage(UIImage.init(named: "mediaPlay"), for: .normal)
        
        self.playButton.addTarget(self, action: #selector(playButtonTapped(sender:)), for: .touchUpInside)
        self.playButton.imageEdgeInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        
        self.playButton.isUserInteractionEnabled = true
        self.addSubview(self.playButton)
        
        self.addSubview(zoomInOutButton)
        self.zoomInOutButton.addTarget(self, action: #selector(zoomInOutButtonTapped(sender:)), for: .touchUpInside)

        addShadowOnButton(button: self.playButton)
        
        self.rewindButton = UIButton.init(type: UIButton.ButtonType.custom)
        
        self.rewindButton.setImage(UIImage.init(named: "RewindButton"), for: .normal)
        
        self.rewindButton.addTarget(self, action: #selector(rewindButtonTapped(sender:)), for: .touchUpInside)
        self.rewindButton.imageEdgeInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        self.addSubview(self.rewindButton)
        addShadowOnButton(button: self.rewindButton)
        
        self.forwardButton = UIButton.init(type: UIButton.ButtonType.custom)
        
        self.forwardButton.setImage(UIImage.init(named: "Forward"), for: .normal)
        
        self.forwardButton.addTarget(self, action: #selector(forwardButtonTapped(sender:)), for: .touchUpInside)
        self.forwardButton.imageEdgeInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        self.addSubview(self.forwardButton)
        addShadowOnButton(button: self.forwardButton)
        
        currentTimeLabel = UILabel.init()
        currentTimeLabel.textAlignment = .center
        currentTimeLabel.font = UIFont.systemFont(ofSize: 15)
        currentTimeLabel.textColor = .white
        self.addSubview(currentTimeLabel)
        
        timeRemainingLabel = UILabel.init()
        timeRemainingLabel.textAlignment = .center
        timeRemainingLabel.font = UIFont.systemFont(ofSize: 15)
        timeRemainingLabel.textColor = .white
        
        self.addSubview(timeRemainingLabel)
        
        if AVPictureInPictureController.isPictureInPictureSupported() {
            self.addPipButton()
        }
        
        self.addCCButton()
        self.updateControls(with: .small)
    }

    private func addShadowOnButton(button: UIButton) {
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 5, height: 5)
        button.layer.shadowRadius = 5
        button.layer.shadowOpacity = 1.0
    }
    
    private func addPipButton() {
        self.pictureInPictureButton =  UIButton(type: .custom)
        self.pictureInPictureButton.isUserInteractionEnabled = true
        self.pictureInPictureButton.addTarget(self, action: #selector(self.togglePictureInPictureMode(sender:)), for: .touchUpInside)
        self.addSubview(self.pictureInPictureButton)
        if #available(iOS 13.0, *) {
            self.setImageOnPip(buttonImage:UIImageView(image: AVPictureInPictureController.pictureInPictureButtonStartImage).image, buttonSelected: false)
            self.setImageOnPip(buttonImage:UIImageView(image: AVPictureInPictureController.pictureInPictureButtonStopImage).image, buttonSelected: true)
        } else {
            self.setImageOnPip(buttonImage: UIImageView(image: UIImage(named: "pip_unselected")).image, buttonSelected: false)
            self.setImageOnPip(buttonImage: UIImageView(image: UIImage(named: "pip_selected")).image, buttonSelected: true)
        }
    }
    
    private func setImageOnPip(buttonImage:UIImage?, buttonSelected:Bool) {
        self.pictureInPictureButton.setImage(buttonImage?.withRenderingMode(.alwaysTemplate), for: buttonSelected ? .selected : .normal)
        self.pictureInPictureButton.imageView?.tintColor = .white
    }
    
    private func addCCButton() {
        self.ccButton = UIButton.init(type: UIButton.ButtonType.custom)
        self.ccButton.addTarget(self, action: #selector(self.ccButtonTapped(sender:)), for: .touchUpInside)
        self.addSubview(self.ccButton)
        self.ccButton.isSelected = self.videoPlayer?.isClosedCaptionEnabled() ?? false
        
        if self.ccButton.isSelected {
            let ccButtonImageView = UIImageView(image: UIImage.init(named: "icon_cc_enable", in: Bundle(for: type(of: self)), compatibleWith: nil))
            self.ccButton.setImage(ccButtonImageView.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            self.ccButton.alpha = 1
        }
        else {
            
            let ccButtonImageView = UIImageView(image: UIImage.init(named: "icon_cc_disable", in: Bundle(for: type(of: self)), compatibleWith: nil))
            self.ccButton.setImage(ccButtonImageView.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            self.ccButton.alpha = 0.5
        }
        self.ccButton.imageView?.tintColor = .white
    }
    
    
    func setupPictureInPicture() {
        if self.videoPlayer != nil {
            self.videoPlayer?.setupPictureInPicture()
        }
    }
    
    @objc func castButtonTapped(sender: UIButton)
    {
        self.videoPlayer?.castButtonTapped(sender: sender)
    }
    
    func startPictureInPictureInline(enable:Bool) {
        guard let videoPlayer = videoPlayer else {
            return
        }
        videoPlayer.startPictureInPictureAutomaticallyFromInline(enablePictureInPictureInline: enable)
    }
    
    func updateControls(with playerControlScreen: PlayerControlScreen)
    {
        self.playerControlScreen = playerControlScreen
        var controlsY: CGFloat = 0.0
        var rightPadding:CGFloat = 0
        var leftPadding:CGFloat = 0.0
        
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            let bottomPadding = window?.safeAreaInsets.bottom
            rightPadding = window?.safeAreaInsets.right ?? 0
            leftPadding = window?.safeAreaInsets.left ?? 0
            
            controlsY -= (bottomPadding ?? 0)
        }
        
        if self.playButton == nil
        {
            return
        }
        
        if self.playerControlType == .liveVideoControls
        {
            timeRemainingLabel.textColor = .red
            timeRemainingLabel.text = "LIVE"
        }
        else
        {
            timeRemainingLabel.textColor = .white
        }
        
        if self.playerControlScreen == .full
        {
            self.fullScreenButton.isHidden = false
            self.chromecastButton.isHidden = false
            controlsY += self.bounds.size.height - (controlsHeight * 2) - 5
            
            let playImage = UIImage.init(named: "mediaPlay", in: Bundle(for: type(of: self)), compatibleWith: nil)
            let playImageSize = playImage?.size ?? CGSize.init(width: 49, height: 57)
            
            self.playButton.frame = CGRect.init(x: ((self.frame.width - playImageSize.width) / 2), y: ((self.frame.height - playImageSize.height) / 2), width: playImageSize.width, height: playImageSize.height)
            
            let fullScreenButtonImageView = UIImageView(image: UIImage.init(named: "Smallscreen", in: Bundle(for: type(of: self)), compatibleWith: nil))
            self.fullScreenButton.setImage(fullScreenButtonImageView.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            self.zoomInOutButton.frame = CGRect(x: self.frame.width - 35 - rightPadding, y: 0, width: 40, height: 40)
            self.ccButton.frame = CGRect(x: 10 + leftPadding, y:0, width:40, height:40)
            self.chromecastButton.frame = CGRect.init(x:  self.frame.width - 80 - rightPadding, y:  0, width: 30, height: 40)
            self.chromecastButton.sizeToFit()
            
            
            switch self.playerControlType {
            case .liveVideoControls:
                self.rewindButton.isHidden = true
                self.forwardButton.isHidden = true
                self.currentTimeLabel.isHidden = true
                self.timeRemainingLabel.frame = CGRect(x: self.frame.width - 25 - rightPadding - timeLabelWidth, y: controlsY + 3 + controlsHeight - 1, width: timeLabelWidth/2, height: controlsHeight)
                self.fullScreenButton.frame = CGRect.init(x: self.frame.width - 25 - rightPadding - 5, y: self.timeRemainingLabel.frame.minY + 2.5, width: 25, height: 25)
                if AVPictureInPictureController.isPictureInPictureSupported() && self.pictureInPictureButton != nil {
                    self.pictureInPictureButton.frame = CGRect.init(x: self.fullScreenButton.frame.minX - 30, y: self.timeRemainingLabel.frame.minY + 2.5, width: 25, height: 25)
                    self.timeRemainingLabel.frame.origin.x = self.pictureInPictureButton.frame.minX - timeLabelWidth/2 - 10
                }
                break
                
            case .streamVideoControls:
                
                self.rewindButton.isHidden = false
                self.forwardButton.isHidden = false
                self.currentTimeLabel.isHidden = false
                
                let forwardButtonImage = UIImage.init(named: "Forward", in: Bundle(for: type(of: self)), compatibleWith: nil)
                let forwardButtonSize = forwardButtonImage?.size ?? CGSize.init(width: 49, height: 57)
                
                self.rewindButton.frame = CGRect.init(x: self.playButton.frame.minX - forwardButtonSize.width - 25, y: ((self.frame.height - forwardButtonSize.height) / 2), width: forwardButtonSize.width, height: forwardButtonSize.height)
                self.forwardButton.frame = CGRect.init(x: self.playButton.frame.maxX + 25, y: ((self.frame.height - forwardButtonSize.height) / 2), width: forwardButtonSize.width, height: forwardButtonSize.height)
                
                self.currentTimeLabel.frame = CGRect(x: 10 + leftPadding, y: controlsY + 3 + controlsHeight - 1, width: timeLabelWidth, height: controlsHeight)
                
                self.fullScreenButton.frame = CGRect.init(x: self.frame.width - 25 - rightPadding - 10, y: self.currentTimeLabel.frame.origin.y + 2.5, width: 25, height: 25)
                
                self.timeRemainingLabel.frame = CGRect(x: self.fullScreenButton.frame.minX - timeLabelWidth, y: self.currentTimeLabel.frame.origin.y,
                                                       width: timeLabelWidth, height: controlsHeight)
                if AVPictureInPictureController.isPictureInPictureSupported() && self.pictureInPictureButton != nil {
                    self.pictureInPictureButton.frame = CGRect.init(x: self.fullScreenButton.frame.minX - 30, y: self.timeRemainingLabel.frame.minY + 2.5, width: 25, height: 25)
                    self.timeRemainingLabel.frame.origin.x = self.pictureInPictureButton.frame.minX - timeLabelWidth
                }
            }
        }
        else if self.playerControlScreen == .small
        {
            if self.fullScreenButton != nil
            {
                self.fullScreenButton.isHidden = false
            }
            if self.forwardButton != nil
            {
                self.forwardButton.isHidden = true
            }
            if self.currentTimeLabel != nil
            {
                self.currentTimeLabel.isHidden = true
            }
            if self.chromecastButton != nil
            {
                self.chromecastButton.isHidden = true
            }
            controlsY = self.bounds.size.height - controlsHeight - 5
            
            if self.playButton != nil
            {
                let playImage = UIImage.init(named: "mediaPlay", in: Bundle(for: type(of: self)), compatibleWith: nil)
                let playImageSize = playImage?.size ?? CGSize.init(width: 49, height: 57)
                self.playButton.frame = CGRect.init(x: ((self.frame.width - playImageSize.width) / 2), y: ((self.frame.height - playImageSize.height) / 2), width: playImageSize.width, height: playImageSize.height)
            }
            let fullScreenButtonImageView = UIImageView(image: UIImage.init(named: "Fullscreen", in: Bundle(for: type(of: self)), compatibleWith: nil))
            self.fullScreenButton.setImage(fullScreenButtonImageView.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            self.fullScreenButton.imageView?.tintColor = UIColor.white
            self.zoomInOutButton.frame = CGRect(x: self.frame.width - 35 - rightPadding, y: 0, width: 40, height: 40)

            self.ccButton.frame = CGRect(x:0, y:0, width:40, height:40)

            switch self.playerControlType {
            
            case .liveVideoControls:
                
                if self.rewindButton != nil
                {
                    self.rewindButton.isHidden = true
                }
                self.timeRemainingLabel.frame = CGRect(x: self.frame.width - 25 - timeLabelWidth, y: controlsY - 1, width: timeLabelWidth/2, height: controlsHeight)
                self.fullScreenButton.frame = CGRect.init(x: self.frame.width - 25 - 5, y: self.timeRemainingLabel.frame.minY + 2.5, width: 25, height: 25)
                if AVPictureInPictureController.isPictureInPictureSupported() && self.pictureInPictureButton != nil {
                    self.pictureInPictureButton.frame = CGRect.init(x: self.fullScreenButton.frame.minX - 30, y: self.timeRemainingLabel.frame.minY + 2.5, width: 25, height: 25)
                    self.timeRemainingLabel.frame.origin.x = self.pictureInPictureButton.frame.minX - timeLabelWidth/2 - 10
                }
                break
                
            case .streamVideoControls:
                if self.rewindButton != nil
                {
                    self.rewindButton.isHidden = false
                }
                if self.currentTimeLabel != nil
                {
                    self.currentTimeLabel.isHidden = false
                }
                if self.forwardButton != nil
                {
                    self.forwardButton.isHidden = false
                }
                
                
                let forwardButtonImage = UIImage.init(named: "Forward", in: Bundle(for: type(of: self)), compatibleWith: nil)
                let forwardButtonSize = forwardButtonImage?.size ?? CGSize.init(width: 49, height: 57)
                
                self.rewindButton.frame = CGRect.init(x: self.playButton.frame.minX - forwardButtonSize.width - 25, y: ((self.frame.height - forwardButtonSize.height) / 2), width: forwardButtonSize.width, height: forwardButtonSize.height)
                self.forwardButton.frame = CGRect.init(x: self.playButton.frame.maxX + 25, y: ((self.frame.height - forwardButtonSize.height) / 2), width: forwardButtonSize.width, height: forwardButtonSize.height)
                
                self.currentTimeLabel.frame = CGRect(x: 10, y: controlsY - 1, width: timeLabelWidth, height: controlsHeight)
                self.fullScreenButton.frame = CGRect.init(x: self.frame.width - 25 - 5, y: self.currentTimeLabel.frame.minY + 2.5, width: 25, height: 25)
                self.timeRemainingLabel.frame = CGRect(x: self.fullScreenButton.frame.minX - timeLabelWidth, y: self.currentTimeLabel.frame.origin.y, width: timeLabelWidth, height: controlsHeight)
                if AVPictureInPictureController.isPictureInPictureSupported() && self.pictureInPictureButton != nil {
                    self.pictureInPictureButton.frame = CGRect.init(x: self.fullScreenButton.frame.minX - 30, y: self.timeRemainingLabel.frame.minY + 2.5, width: 25, height: 25)
                    self.timeRemainingLabel.frame.origin.x = self.pictureInPictureButton.frame.minX - timeLabelWidth
                }
                
                break
            }
        }
        addGradientView()
    }
    
    func updatePlayerControlsType(playerControlType:PlayerControlType) {
        self.playerControlType = playerControlType
        self.updateControls(with: self.playerControlScreen)
    }
    private func addGradientView()
    {
        if gradientLayer != nil
        {
            gradientLayer.removeFromSuperlayer()
            gradientLayer = nil
        }
        
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect.init(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        gradientLayer.colors = [UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor, UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor]
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func updateTimeLabel(timeRemaining:Double, elapsedTime:Double) {
        if self.playerControlType == .liveVideoControls {
            updateTimeLabel(remainingTimeLabelText: "LIVE", currentTimeLabelText: "")
            timeRemainingLabel.textColor = .red
        }
        else {
            let timeRemainigHours: Double = timeRemaining / 3600
            var timeRemainingText:String = ""
            if timeRemainigHours >= 1
            {
                timeRemainingText = String(format: "%02d:%02d:%02d", ((lround(timeRemaining) / 3600) % 3600), ((lround(timeRemaining) / 60) % 60), lround(timeRemaining) % 60)
            }
            else
            {
                timeRemainingText = String(format: "%02d:%02d", ((lround(timeRemaining) / 60) % 60), lround(timeRemaining) % 60)
            }
            
            let elapsedTimeHours = elapsedTime / 3600
            var elapsedTimeText:String = ""
            if elapsedTimeHours >= 1
            {
                elapsedTimeText = String(format: "%02d:%02d:%02d", ((lround(elapsedTime) / 3600) % 3600), ((lround(elapsedTime) / 60) % 60), lround(elapsedTime) % 60)
            }
            else
            {
                elapsedTimeText = String(format: "%02d:%02d", ((lround(elapsedTime) / 60) % 60), lround(elapsedTime) % 60)
            }
            updateTimeLabel(remainingTimeLabelText: timeRemainingText, currentTimeLabelText: elapsedTimeText)
        }
    }
    
    func updateTimeLabelOnStart() {
        if let currentTime = videoPlayer?.getCurrentTime(), let remainingTime = videoPlayer?.getCurrentVideoTimeLeft() {
            updateTimeLabel(timeRemaining: remainingTime, elapsedTime: currentTime)
        }
    }
    
    private func updateTimeLabel(remainingTimeLabelText: String, currentTimeLabelText:String) -> Void {
        timeRemainingLabel.text = remainingTimeLabelText
        currentTimeLabel.text = currentTimeLabelText
    }
    
    func setPlayButtonState(state: Bool) {
        self.playButton.isSelected = state
    }
    
    func getPlayButtonState() -> Bool {
        if self.playButton != nil
        {
            return self.playButton.isSelected
        }
        else
        {
            return false
        }
    }
    
    @objc func ccButtonTapped(sender: UIButton) -> Void {
        self.ccButton.isSelected = !self.ccButton.isSelected
        if self.ccButton.isSelected {
            
            let ccButtonImageView = UIImageView(image: UIImage.init(named: "icon_cc_enable", in: Bundle(for: type(of: self)), compatibleWith: nil))
            self.ccButton.setImage(ccButtonImageView.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            self.ccButton.alpha = 1
        }
        else {
            
            let ccButtonImageView = UIImageView(image: UIImage.init(named: "icon_cc_disable", in: Bundle(for: type(of: self)), compatibleWith: nil))
            self.ccButton.setImage(ccButtonImageView.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            self.ccButton.alpha = 0.5
        }
        
        self.videoPlayer?.toggleClosedCaption(enable: self.ccButton.isSelected)
    }
    
    @objc func fullScreenButtonTapped(sender: UIButton)
    {
        self.videoPlayer?.goFullScreen()
    }
    
    @objc func playButtonTapped(sender: UIButton) -> Void
    {
        if self.videoPlayer != nil
        {
            if self.playButton.isSelected
            {
                self.videoPlayer?.pause()
            }
            else
            {
                self.videoPlayer?.play()
            }
        }
    }
    
    @objc func rewindButtonTapped(sender: UIButton) -> Void {
        if self.videoPlayer != nil
        {
            let currentTime: Double = (self.videoPlayer?.getCurrentTime())!
            self.videoPlayer?.seekTo(seconds: (currentTime - (seekBackwardDuration ?? 5)))
        }
    }
    
    @objc func forwardButtonTapped(sender: UIButton) -> Void {
        if self.videoPlayer != nil
        {
            let currentTime: Double = (self.videoPlayer?.getCurrentTime())!
            self.videoPlayer?.seekTo(seconds: (currentTime + (seekForwardDuration ?? 5)))
        }
    }
    
    @objc private func togglePictureInPictureMode(sender:UIButton) {
        if self.videoPlayer != nil {
            self.videoPlayer?.pictureInPictureClicked(isPipSelected: sender.isSelected)
        }
    }
    
    @objc func zoomInOutButtonTapped(sender: UIButton) -> Void
    {
        sender.isSelected = !sender.isSelected
        if self.videoPlayer != nil {
            if sender.isSelected {
                self.videoPlayer?.setVideoPlayerGravity(videoPlayerGravity: .resizeAspectFill)
            }
            else {
                self.videoPlayer?.setVideoPlayerGravity(videoPlayerGravity: .resizeAspect)
            }
        }
    }
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}
