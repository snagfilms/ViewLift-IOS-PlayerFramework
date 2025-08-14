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

class CustomVideoControls: UIView, CustomPlayerSkinProtocol {
    
    func updatePlayButton() {
        
    }

    
    var isAdOnMainView: Bool
    
    var adRunningOnInternalPlayer: Bool

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
    private var videoSeekSlider:CustomSlider!
    private var ccButton: UIButton!
    private var isDVREnabled: Bool = false
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
        self.playerControlScreen = .full
        self.isAdOnMainView = false
        self.adRunningOnInternalPlayer = false
        super.init(frame: frame)
        self.createView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewLoad() -> Void{
        var controlsY: CGFloat = self.bounds.size.height - controlsHeight - 5
        
        var leftPadding:CGFloat = 0.0
        let window = UIApplication.shared.keyWindow
        let bottomPadding = window?.safeAreaInsets.bottom
        leftPadding = window?.safeAreaInsets.left ?? 0
        controlsY -= (bottomPadding ?? 0)
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
        self.setupSlider()
        self.updateControls(with: .small)
    }
    
    private func setupSlider(){
        videoSeekSlider = CustomSlider(sliderType: .streamVideoSlider, frame: .zero, isDVREnabled: false)
        self.addSubview(videoSeekSlider)
        videoSeekSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        videoSeekSlider.addTarget(self, action: #selector(sliderBeganTracking(_:)), for: .touchDown)
        videoSeekSlider.addTarget(self, action: #selector(sliderEndedTracking(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        videoSeekSlider.isHidden = true
    }
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        if !sender.isTracking {
           // videoPlayer.slider
        }
    }

    @objc private func sliderBeganTracking(_ sender: UISlider) {
        print("Tracking Begin, \(sender.isTracking) \(sender.isContinuous)")
        //delegate?.sliderBeganTracking(newSeekValue: Double(sender.value))
        self.videoPlayer?.sliderBeganTracking(newSeekValue: Double(sender.value))
    }

    @objc private func sliderEndedTracking(_ sender: UISlider) {
        print("Tracking Ended \(sender.isTracking)")
        //delegate?.sliderEndedTracking(newSeekValue: Double(sender.value))
        self.videoPlayer?.sliderEndedTracking(newSeekValue: Double(sender.value))
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
        self.ccButton.isHidden = true
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
    
    func updateControls(with playerControlScreen: PlayerControlScreen){
        if videoPlayer?.isDVREnabled() ?? false {
            self.isDVREnabled = true
        }
        self.playerControlScreen = playerControlScreen
        var controlsY: CGFloat = 0.0
        var rightPadding:CGFloat = 0
        var leftPadding:CGFloat = 0.0
        
        let window = UIApplication.shared.keyWindow
        let bottomPadding = window?.safeAreaInsets.bottom
        rightPadding = window?.safeAreaInsets.right ?? 0
        leftPadding = window?.safeAreaInsets.left ?? 0
        
        controlsY -= (bottomPadding ?? 0)
        
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
        let width: CGFloat = self.frame.width * 0.7
        let x = self.frame.width - width
            videoSeekSlider.frame = CGRect(x: x/2, y: timeRemainingLabel.center.y, width: width, height: 50)
        videoSeekSlider.backgroundColor = .blue
        if let isLiveVideo = videoPlayer?.isLiveVideo(), isLiveVideo, !isDVREnabled{
            
             videoSeekSlider.isUserInteractionEnabled = false
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
        self.videoPlayer?.goFullScreen(true)
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
    private func updateSliderConfig() {
        
        videoSeekSlider.updateSliderConfig(sliderType: (self.playerControlType == .liveVideoControls) ? .liveVideoSlider : .streamVideoSlider, isDVREnabled: self.isDVREnabled)
    }
    
    func updateControlsBasedOnDVRFlag(isDVREnabled: Bool) {
        if playerControlType == .liveVideoControls {
            self.isDVREnabled = isDVREnabled
            self.updateSliderConfig()
            DispatchQueue.main.async {
                self.updatePlayerControlVisibility()
            }
        }
    }
    
    private func updatePlayerControlVisibility() {
        DispatchQueue.main.async {
    
            switch self.playerControlType {
            case .liveVideoControls:

                self.forwardButton.isHidden = self.isDVREnabled
                self.rewindButton.isHidden = self.isDVREnabled


                
            case .streamVideoControls:
               // self.goLivebutton.isHidden = true
         break
            default:
           
                break
            }
            
        
        }
    }
    func updateSliderDuration(sliderValue:Double) {
        if self.videoSeekSlider != nil {
            self.videoSeekSlider?.value = Float(sliderValue)
            debugPrint("sliderValue", sliderValue)
        }

    }
    
}

class CustomSlider: UISlider
{
    enum SliderType
    {
        case liveVideoSlider
        case streamVideoSlider
        case streamAudioSlider
        case volumeSlider
        case screenBrightnessSlider
        case verticalVideoSlider
    }
    
    var cuePoints: Array<Double> = []
    var duration: TimeInterval!
    var sliderColor: String!
    private var _viewType: SliderType?
    private var isDVRSupported: Bool = true
    var viewType: SliderType? {
        get {
            return _viewType
        } set(newValue) {
            _viewType = newValue
            self.setNeedsDisplay()
        }
    }
    var cueViews: [CuePointView]? = []
    var onValueChanged: ((Float) -> Void)?
//
//    override var value: Float {
//        didSet {
//            cueViews?.forEach { $0.onValueChanged?(value) }
//        }
//    }
//
    init(sliderType: SliderType, frame: CGRect, isDVREnabled:Bool = false) {
        _viewType = sliderType
        isDVRSupported = isDVREnabled
        super.init(frame: CGRect.zero)
        self.setThumbImage(nil, for: .normal)
        if sliderType == .liveVideoSlider {
            self.value = 1.0
        }
        else if sliderType == .screenBrightnessSlider {
            self.value = Float(UIScreen.main.brightness)
        }
        else {
            self.value = 0.0
        }
    }
    
    func updateSliderConfig(sliderType: SliderType, isDVREnabled:Bool = false) {
        DispatchQueue.main.async {
            self._viewType = sliderType
            self.isDVRSupported = isDVREnabled
            self.setThumbImage(nil, for: .normal)
            if sliderType == .liveVideoSlider {
                self.value = 1.0
            }
            else if sliderType == .screenBrightnessSlider {
                self.value = Float(UIScreen.main.brightness)
            }
            else {
                
                self.value = 0.0
            }
            
            if sliderType == .liveVideoSlider {
                if isDVREnabled{
                    self.isUserInteractionEnabled = true
                    self.setThumbImage(nil, for: .normal)
                }
                else{
                    self.isUserInteractionEnabled = false
                    self.setThumbImage(nil, for: .normal)
                }
            }
            if sliderType == .verticalVideoSlider {
                self.isUserInteractionEnabled = true
                self.setThumbImage(nil, for: .normal)
            }
        }
    }
    
    private var trackHeight: CGFloat = 6
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
//        cueViews?.forEach { $0.onValueChanged?(value) }
        if _viewType == .streamAudioSlider {
            return CGRect(origin: bounds.origin, size: CGSize(width: bounds.width, height: trackHeight))
        }
        return CGRect(origin: CGPoint.init(x: bounds.origin.x, y: (bounds.height - bounds.origin.y - 2)/2), size: CGSize(width: bounds.width, height: 2))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setThumbImage(#imageLiteral(resourceName: "NoKnob.png"), for: .normal)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCueViews()
    }

    override func draw(_ rect: CGRect) {
        self.maximumTrackTintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4322559932)
        self.tintColor = .clear

        self.minimumTrackTintColor = .red

        switch _viewType {
        case .volumeSlider:
            self.setThumbImage(nil, for: .normal)
            break
        case .screenBrightnessSlider:
            if let image = UIImage(named: "Knob") {
                self.setThumbImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
            }
            else {
                self.setThumbImage(nil, for: .normal)
            }
            break
        case .streamAudioSlider:
            if let image = UIImage(named: "Knob") {
                self.setThumbImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
                self.tintColor = .blue
            }
            else {
                self.setThumbImage(nil, for: .normal)
            }
            break
        case .liveVideoSlider:
            if ((self.duration != nil) && self.duration > 0) || isDVRSupported{
                
                if isDVRSupported{
                    self.setThumbImage(nil, for: .normal)
                }
                else{
                    self.setThumbImage(nil, for: .normal)
                }
                self.tintColor = .blue
                if isDVRSupported{
                    self.isUserInteractionEnabled = true
                }
                else{
                    self.isUserInteractionEnabled = false
                }
                self.value = 1.0
            }
            break
        case .streamVideoSlider:
            if (self.duration != nil) && self.duration > 0 && self.cuePoints.count > 0 {
                for view in self.subviews {
                    if view.tag != 0
                    {
                        view.removeFromSuperview()
                    }
                }
                cueViews?.forEach({$0.removeFromSuperview()})
                cueViews = []
                
                let factor: Double = Double(rect.size.width)/self.duration
                for cuePoint in self.cuePoints {
                    let pos: CGFloat = CGFloat(cuePoint) * CGFloat(factor)
                    let cueView = CuePointView(positionX: pos, centerY: rect.midY)
                    cueView.tag = 11
                    cueView.value = cuePoint
                    self.addSubview(cueView)
                    self.bringSubviewToFront(cueView)
                    cueViews?.append(cueView)
                }
            }

            self.setThumbImage(nil, for: .normal)
            break
        case .verticalVideoSlider:
            self.isUserInteractionEnabled = false
            self.setThumbImage(nil, for: .normal)
//            self.setThumbImage(nil, for: .normal)
//            self.isUserInteractionEnabled = true
            break
        case .none:
            break
        }

    }
    
    override func accessibilityIncrement() {
        self.value += 0.01
        sendActions(for: .valueChanged)
        updateAccessibilityValue()
    }
    
    override func accessibilityDecrement() {
        self.value -= 0.01
        sendActions(for: .valueChanged)
        updateAccessibilityValue()
    }
    
    private func updateAccessibilityValue() {
        let percentage = Int(value * 100)
        self.accessibilityValue = "\(percentage) percent"
    }
    
    func setCuePoints(cuePoints: [Double], duration: TimeInterval) -> Void {
        if _viewType == .streamVideoSlider {
            self.cuePoints = cuePoints
            self.duration = duration
            self.setNeedsDisplay()
        }
    }
    
    func updateSliderView() {
        self.maximumTrackTintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4322559932)
        self.tintColor = .clear
        self.minimumTrackTintColor = .red

        if let image = UIImage(named: "Knob") {
            self.setThumbImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        else {
            self.setThumbImage(nil, for: .normal)
        }
    }
    
    func updateCueViews() {
        guard _viewType == .streamVideoSlider,
              let duration = self.duration,
              duration > 0,
              self.cuePoints.count > 0 else { return }

        // Clear old cue views
        for view in self.subviews {
            if view.tag != 0 {
                view.removeFromSuperview()
            }
        }
        cueViews?.forEach { $0.removeFromSuperview() }
        cueViews = []

        let factor: Double = Double(self.bounds.width) / duration
        let y = (self.bounds.height / 2)
        for cuePoint in self.cuePoints {
            let pos: CGFloat = CGFloat(cuePoint) * CGFloat(factor)
            let cueView = CuePointView(positionX: pos, centerY: y)
            cueView.tag = 11
            cueView.value = cuePoint
            self.addSubview(cueView)
            cueViews?.append(cueView)
        }
    }

}


class CuePointView: UIView {

    var value: Double?
    
    var onValueChanged: ((Float) -> Void)?

    // Initializer with position and optional size
    init(positionX: CGFloat, centerY: CGFloat, size: CGSize = CGSize(width: 2, height: 2)) {
        let origin = CGPoint(x: positionX, y: centerY - size.height / 2)
        let frame = CGRect(origin: origin, size: size)
        super.init(frame: frame)
        
        self.tag = 11
        self.backgroundColor = .yellow
        self.isUserInteractionEnabled = false // Optional
        self.layer.cornerRadius = size.width / 2 // Make it round if width == height
        self.clipsToBounds = true
//        self.changeValue()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    func changeValue() {
//        self.onValueChanged = { [weak self] valueOfSlider in
//            guard let self = self else { return }
//            if let playerMfe = self.superview?.superview?.superview?.superview?.superview?.parentViewController as? VLPlayerMFEController {
//                let currentDuration = playerMfe.vlPlayer.getCurrentVideoDuration()
//                if (Double(valueOfSlider) * (currentDuration ?? 0)) + 100 > Double(value ?? 0.0) {
//                    self.backgroundColor = .clear
//                } else {
//                    self.backgroundColor = .yellow
//                }
//            }
//        }
//    }
}



extension String{
    func hexStringToUIColor() -> UIColor {
        
        var cString:String = self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString = String(cString[cString.index(after: cString.startIndex)...])//cString.substring(from: cString.index(after: cString.startIndex))
        }
        
        if ((cString.count) != 6) {
            return UIColor.white
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}

extension CustomVideoControls{
    
    func sliderValueChanged(newSeekValue: Double) {
        debugPrint("newSeekValue sliderValueChanged : \(newSeekValue)")
      
    }
}
