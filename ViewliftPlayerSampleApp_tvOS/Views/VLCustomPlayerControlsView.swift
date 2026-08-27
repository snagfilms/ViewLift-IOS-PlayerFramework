//
//  VLCustomPlayerControlsView.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 17/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit
import VLPlayerLib
import AVFoundation
import AVKit

enum ControlsType{
    case videoStream
    case live(isDVR: Bool)
}



protocol PlayerControlsViewDelegate: AnyObject {
    func videoStartedPlaying(timestamp: Double)
    func updateCurrentTime(currentTime: Double, totalTime: Double)
    func playPause(isPlaying: Bool)
    func customPlayerControls(isHidden: Bool)
}
    

protocol PlayerControlsDelegate :AnyObject {
    func didRequestRestart()
    func didTogglePlayPause()
    func seekTo(seconds: Double)
    func seekToLivePosition()
    
    func getCurrentVideoDuration() -> Double?
    func setAudioSelected(selectedAudio: String)
    
    func setCCFontSize()
    
    func setPlaybackQuality(playbackQuality: String)
    func setClosedCaption(selectedKey: String, selectedIndex: Int)
    func getAllContentAudioLanguageList()  -> [String]?
    
    func getAllVideoPlaybackQualityList()  -> [String]?
    func getAllClosedCaptionList()  -> [String]?
    
    func getStartOverTime() -> Double?
    func isLiveVideo() -> Bool
    func isDVREnabled () -> Bool
    func setPlaybackRate(playbackSpeed:Float)
    func getTrickPlayData(_ value: Double) async -> (image: UIImage?, time: String?)
    /// Wall-clock date of the live edge for DVR chaptering. Returning `nil` lets the
    /// controls fall back to the device clock.
    func getLiveEdgeDate() -> Date?
    func seekToChapter(startTime: Double)
}

extension PlayerControlsDelegate {
    func getLiveEdgeDate() -> Date? { nil }
}

enum FontStyleValues : String, CaseIterable {
    case small = "Small"
    case regular = "Regular"
    case large = "Large"
    
    var size: String {
        switch self {
#if os(iOS)
        case .small: return "12"
        case .regular: return "14"
        case .large: return "18"
#else
        case .small: return "32"
        case .regular: return "38"
        case .large: return "44"
#endif
        }
    }
    
    static func from(size: String) -> FontStyleValues? {
        return allCases.first(where: { $0.size == size })
    }
}


class VLCustomPlayerControlsView: UIView, PlayerControlsViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    enum FocusState{
        case subtitle
        case setting
    }
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var playPauseImageView: UIImageView?
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var playerControlsView: UIView!
    @IBOutlet weak var liveButton: UIButton!
    @IBOutlet weak var startFromBeginingButton: UIButton!
    @IBOutlet weak var slowMoButton: UIButton!
    @IBOutlet weak var subTitleButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var totalDurationLabel: UILabel!
    @IBOutlet weak var elapsedDurationLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sliderView: TvOSSlider!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var innerStackView: UIStackView!
    @IBOutlet weak var playerControlsStackView: UIStackView!
    @IBOutlet weak var controlsStackView: UIStackView!
    @IBOutlet weak var imageView_TVE: UIImageView!
    @IBOutlet weak var progressLabelLeadingConstraint: NSLayoutConstraint!
    private var isSlowmoEnabled = false
   #if os(tvOS)
    private var optionView: PlayerSettingView_tvOS?
    #endif
    weak var delegate: PlayerControlsDelegate?
    var isAutoPlayFeatureEnabled = false
    private var isFullScreen = false
    private var currentFocusState: FocusState = .setting
    private var hidingAlpha = 0.00
    var isCaptionEmbedded: Bool = true
    var hasVideoStartedPlaying: Bool = false
    private var toLiveButtonTopFocusGuide: UIFocusGuide?
    private var toSlowMoButtonTopFocusGuide: UIFocusGuide?
    private var toSlowMoButtonBottomFocusGuide: UIFocusGuide?
    private var currentControlsType: ControlsType = .videoStream
    var isAdOnMainView: Bool = false
    var adRunningOnInternalPlayer: Bool = false
    var isChapteringCuePointEnable = false
    var chapteringCuePoints: [ChapteringCuePoint] = []
    var chapteringDuration: TimeInterval = 0
    private var pendingSliderSeekPosition: TimeInterval?
    // Lives in the skin nib; hidden by default and only shown when chaptering is
    // enabled and cue points exist.
    // Provided by the skin nib. All chapter-collection logic lives in
    // VLCustomPlayerControlsView+ChapteringSupport.
    @IBOutlet weak var chapteringCollectionView: UICollectionView?
    @IBOutlet weak var chapteringCollectionBottomConstraint: NSLayoutConstraint!
    var lastReloadedChapteringCuePointCount = -1

    var isDVRChaptering: Bool {
        if case .live(let isDVR) = currentControlsType { return isDVR }
        return false
    }
    
    internal var trickPlayImageView: UIImageView?
    internal var trickPlayTimeView: UILabel?
    internal var trickPlayType: TrickPlayType = .auto
    internal enum TrickPlayType {
        case thumbnail, time, auto, none
    }
    
     init(frame: CGRect, config: VLPlayer.PlayerControlsViewThemeConfiguration?, isChapteringCuePointEnable: Bool = false){
        self.isChapteringCuePointEnable = isChapteringCuePointEnable
        super.init(frame: frame)
        loadView()
        setupAppearance()
        updateLocalizedTextToButtons()
        setupActions()
       #if os(tvOS)
        setupFocusGuide()
        disableAllFocusGuide()
        #endif
        setupInitialValues()
       #if os(tvOS)
        if isChapteringCuePointEnable {
            sliderView.applyChapteringStyle(progressColor: UIColor.fromHex("#ABAAAC"))
            chapteringCollectionView?.reloadData()
        }
        #endif

        debugPrint("delegate?.getAllVideoPlaybackQualityList() \(String(describing: delegate?.getAllVideoPlaybackQualityList()))")
        
       debugPrint("loadView",  self.containsHiddenSubview())
        
    }

    func updateTitleLabel(text: String?){
        titleLabel.text = text
    }
   #if os(tvOS)
    private func setupFocusGuide() {
        addFocusGuideToControlsStackView()
        
        addFocusGuideToLiveStackView1()
        addFocusGuideToLiveStackView2()
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment]{
        switch currentFocusState {
        case .subtitle:
            if let optionView = optionView{
                return [optionView]
            }
            return [subTitleButton]
        case .setting:
            if let optionView = optionView{
                return [optionView]
            }
            return [settingButton]
        }
    }
    
    
    private func enabledLIVETopFocusGuide() {
        if let toLiveButtonTopFocusGuide,
           !toLiveButtonTopFocusGuide.isEnabled {
            toLiveButtonTopFocusGuide.isEnabled = true
        }
        
        if let toSlowMoButtonTopFocusGuide,
           !toSlowMoButtonTopFocusGuide.isEnabled {
            toSlowMoButtonTopFocusGuide.isEnabled = true
        }
    }
    
    private func disableAllFocusGuide() {
        if let toLiveButtonTopFocusGuide,
           toLiveButtonTopFocusGuide.isEnabled {
            toLiveButtonTopFocusGuide.isEnabled = false
        }
        if let toSlowMoButtonTopFocusGuide,
           toSlowMoButtonTopFocusGuide.isEnabled {
            toSlowMoButtonTopFocusGuide.isEnabled = false
        }
        if let toSlowMoButtonBottomFocusGuide,
           toSlowMoButtonBottomFocusGuide.isEnabled {
            toSlowMoButtonBottomFocusGuide.isEnabled = false
        }
    }
    #endif
    
    @objc func sliderValueChanges(slider: TvOSSlider) {
        let duration = delegate?.getCurrentVideoDuration() ?? 0.0
        var timeToSeek = Double(slider.value) * duration
        if isChapteringCuePointEnable, isDVRChaptering, duration > 0 {
            timeToSeek = max(timeToSeek, min(1.0, duration))
        }
        pendingSliderSeekPosition = timeToSeek
        self.delegate?.seekTo(seconds: timeToSeek)
        updateLabelPosition(CGFloat(slider.value))
        if isChapteringCuePointEnable, isDVRChaptering {
            elapsedDurationLabel.text = chapteringDVRTimeText(currentTime: timeToSeek, totalTime: duration)
        } else {
            elapsedDurationLabel.text = timeToSeek.getTimeInString()
        }
//        updateSeekingThumbnail(slider)
    }



    
    func setupInitialValues(){
        updatePlayPauseVisual(imageNamed: "play_newUI")
        sliderView.value = 0
        elapsedDurationLabel.text = "--:--"
        totalDurationLabel.text = "--:--"
      

        updateLabelPosition()
        sliderView.minimumTrackTintColor = UIColor.fromHex("#ABAAAC")
        sliderView.maximumTrackTintColor = UIColor.fromHex("#686768")
     
        startFromBeginingButton.roundWithBorder(corners: .allCorners, radius: 12, borderWidth: 2, borderColor: UIColor.white.cgColor)
        startFromBeginingButton.isHidden = true
        subTitleButton.isHidden = true
        settingButton.isHidden = true
        liveButton.isHidden = true
        sliderView.isUserInteractionEnabled = false
    }
    
    func videoStartedPlaying(timestamp: Double) {
        if let isLive = delegate?.isLiveVideo(), isLive{
            if let isDVR = delegate?.isDVREnabled(), isDVR{
                self.currentControlsType = .live(isDVR: true)
            }else{
                self.currentControlsType = .live(isDVR: false)
            }
        }
        self.hasVideoStartedPlaying = true
        updatePlayPauseVisual(imageNamed: "pause_newUI")
        
        switch self.currentControlsType {
        case .videoStream:
            self.setupForVideoStream(currentTime: timestamp)
        case .live(let isDVR):
            self.setupForLiveStream(isDVR: isDVR, currentTime: timestamp)
        }
        settingButton.isHidden = false
        subTitleButton.isHidden = false
    }
    
    func customPlayerControls(isHidden: Bool) {
        if isHidden {
            resetViewsWhenControlsHide()
        }
    }
    
    func setupForVideoStream(currentTime: Double){
        startFromBeginingButton.isHidden = false
        sliderView.isUserInteractionEnabled = true
        sliderView.value = 0.0
    }
    
    func setupForLiveStream(isDVR: Bool, currentTime: Double){
        self.liveButton.isHidden = false
        self.liveButton.isUserInteractionEnabled = true
        sliderView.value = 1.0
        if isDVR{
            sliderView.isUserInteractionEnabled = true
            elapsedDurationLabel.isHidden = false
            totalDurationLabel.isHidden = false
        }else{
            sliderView.isUserInteractionEnabled = false
            elapsedDurationLabel.isHidden = true
            totalDurationLabel.isHidden = false
            self.updateTimeForLive(currentTime: currentTime)
        }
       #if os(tvOS)
        enabledLIVETopFocusGuide()
        if let toSlowMoButtonBottomFocusGuide,
           toSlowMoButtonBottomFocusGuide.isEnabled {
            toSlowMoButtonBottomFocusGuide.isEnabled = false
        }
        #endif
    }

    func updateLabelPosition(_ value: CGFloat? = nil) {
        let sliderValue: CGFloat = value ?? CGFloat(sliderView.value)
        let value = sliderValue * sliderView.frame.width
        let labelX = sliderView.frame.origin.x +  value
        let maxX = (sliderView.frame.width - elapsedDurationLabel.frame.width)
        progressLabelLeadingConstraint.constant = labelX > maxX ? maxX : labelX
        if elapsedDurationLabel.frame.intersects(totalDurationLabel.frame){
            totalDurationLabel.isHidden = true
        }else{
            if delegate?.isDVREnabled() ?? false{
                totalDurationLabel.isHidden = true
            }else{
                totalDurationLabel.isHidden = false
            }
            
        }
    }

    func updatePlayerContentAndControls(isLiveVideo: Bool) {
        if isLiveVideo {
            self.totalDurationLabel.isHidden = true
            self.elapsedDurationLabel.isHidden = true
            self.startFromBeginingButton.isHidden = true
            self.sliderView.isUserInteractionEnabled = false
            self.liveButton.isUserInteractionEnabled = true
            self.liveButton.superview?.isHidden = false
        }
    }

    private func setupActions(){
        settingButton.addTarget(self, action: #selector(settingButtonTapped(sender:)), for: .primaryActionTriggered)
        subTitleButton.addTarget(self, action: #selector(subTitleButtonTapped(sender:)), for: .primaryActionTriggered)
        slowMoButton.addTarget(self, action: #selector(slowmoButtonTapped(sender:)), for: .primaryActionTriggered)
        startFromBeginingButton.addTarget(self, action: #selector(startFromBeginingButtonTapped(sender:)), for: .primaryActionTriggered)
        liveButton.addTarget(self, action: #selector(liveButtonTapped(sender:)), for: .primaryActionTriggered)
        sliderView.addTarget(self, action: #selector(sliderValueChanges), for: .valueChanged)
    }
    
    private func updateLocalizedTextToButtons(){
        startFromBeginingButton.setTitle("Start from beginning", for: .normal)
        slowMoButton.setTitle("Slow Mo", for: .normal)
        liveButton.setTitle("Live", for: .normal)
    }
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func loadView() {
       #if os(tvOS)
        Bundle.main.loadNibNamed("VLCustomPlayerSkin_tvOS", owner: self, options: nil)
        addSubview(contentView)
        if isChapteringCuePointEnable {
            setupChapteringCollectionView()
        }
        #else
        Bundle.main.loadNibNamed("VLCustomPlayerSkin_iOS", owner: self, options: nil)
        addSubview(contentView)
        #endif
        
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
        #if os(tvOS)
        if isChapteringCuePointEnable {
            updateChapteringCuePointsIfNeeded(duration: chapteringDuration)
        }
        #endif
    }


    private func setupAppearance(){
        [slowMoButton, startFromBeginingButton, liveButton].forEach { button in
            button?.contentEdgeInsets = UIEdgeInsets(top: 15, left: 20, bottom: 15, right: 20)
        }
        [subTitleButton, settingButton].forEach { button in
            button?.contentEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        }
        let settingsImage = UIImage(named: "settings")
        settingButton.setImage(settingsImage, for: .normal)
        settingButton.setImage(settingsImage, for: .focused)
        let subTitleImage = UIImage(named: "subtitle")
        subTitleButton.setImage(subTitleImage, for: .normal)
        subTitleButton.setImage(subTitleImage, for: .focused)
        setGradient(gradientView: gradientView)
       // gradientView.backgroundColor = .green.withAlphaComponent(0.5)
        [elapsedDurationLabel, totalDurationLabel].forEach { label in
            
        }

        liveButton.setTitleColor(UIColor.fromHex("#EBEBEB"), for: .normal)
        liveButton.backgroundColor = UIColor.fromHex("#FF3030")
        liveButton.round(corners: .allCorners, radius: 12)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 60)
    }
    
    func setGradient(gradientView: UIView){
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor,
            UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        ]
        layer.locations = [0, 1]
        layer.startPoint = CGPoint(x: 0.25, y: 0.5)
        layer.endPoint = CGPoint(x: 0.75, y: 0.5)
        layer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 1, ty: 0))
        layer.bounds = gradientView.bounds.insetBy(dx: -0.5*gradientView.bounds.size.width, dy: -0.5*gradientView.bounds.size.height)
        layer.position = gradientView.center
        gradientView.layer.addSublayer(layer)
    }
    
   #if os(tvOS)
    private func addOptionsView(type: MenuType){
 
        let viewWidth = frame.width - (frame.width * 0.4)
        let optionView = PlayerSettingView_tvOS(frame: CGRect(x: viewWidth, y: 0, width: frame.width * 0.4, height: frame.height), playerMenuModel: type == .setting ? createSettingsData(type: .setting) : createSubTitlesData(type: .subtitle))

        self.addSubview(optionView)

        optionView.translatesAutoresizingMaskIntoConstraints = false
        optionView.widthAnchor.constraint(equalToConstant: frame.width * 0.4).isActive = true
        optionView.heightAnchor.constraint(equalToConstant: frame.height).isActive = true

        optionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: viewWidth).isActive = true
        optionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
        self.optionView = optionView
        self.optionView?.delegate = self
    }
    #endif
    private func showToastForEmptyPlaybackQualityList() -> Bool {
        if self.getVideoPlaybackQualityList() == nil {
            return true
        }
        if let optionsList = self.getVideoPlaybackQualityList(), optionsList.isEmpty {
            return true
        }
        return false
    }

    
}

extension VLCustomPlayerControlsView{

    func hidePlayerControls(){

    }
    //  func showHideViewWith(alpha: F)
    @objc func settingButtonTapped(sender: UIButton){
    #if os(tvOS)
        currentFocusState = .setting
        if optionView == nil{
            addOptionsView(type: .setting)
            playerControlsStackView.alpha = hidingAlpha
            setChapteringCollectionHidden(true)
            updateFocusOnPlayerControls()
            gradientView.isHidden = true
        }else{
            playerControlsStackView.alpha = 1.0
            setChapteringCollectionHidden(false)
            gradientView.isHidden = false

        }
#endif

    }
    
    func updateFocusOnPlayerControls(){
        playerControlsStackView.isUserInteractionEnabled = false

        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            self.playerControlsStackView.isUserInteractionEnabled = true
        }
    }




    @objc func subTitleButtonTapped(sender: UIButton){
        #if os(tvOS)
        currentFocusState = .subtitle
        if optionView == nil{
            addOptionsView(type: .subtitle)
            playerControlsStackView.alpha = hidingAlpha
            setChapteringCollectionHidden(true)
            updateFocusOnPlayerControls()
            gradientView.isHidden = true
        }else{
            playerControlsStackView.alpha = 1.0
            setChapteringCollectionHidden(false)
            gradientView.isHidden = false
        }
        #endif
    }
    @objc func slowmoButtonTapped(sender: UIButton){
        isSlowmoEnabled.toggle()
        self.delegate?.setPlaybackRate(playbackSpeed: isSlowmoEnabled ? 0.5 : 1.0)
        playPause(isPlaying: true)
    }


    @objc func liveButtonTapped(sender: UIButton){
        let duration = delegate?.getCurrentVideoDuration() ?? chapteringDuration
        if duration > 0 {
            // Replace the position recorded while scrubbing so stale progress callbacks
            // cannot keep the controls at the old DVR offset after jumping to Live.
            pendingSliderSeekPosition = duration
        } else {
            pendingSliderSeekPosition = nil
        }
        sliderView.setValue(1.0, animated: true)
        updateLabelPosition(1.0)
        if isChapteringCuePointEnable, isDVRChaptering, duration > 0 {
            elapsedDurationLabel.text = chapteringDVRTimeText(currentTime: duration, totalTime: duration)
            selectChapteringCuePoint(at: duration)
        }
        delegate?.seekToLivePosition()
    }

    @objc func startFromBeginingButtonTapped(sender: UIButton){


        self.delegate?.didRequestRestart()
    }

    private func updateTimeForLive(currentTime: Double){
        totalDurationLabel.text = currentTime.getTimeInString()
    }
    
    private func updateTimeForVideoStream(currentTime: Double, totalTime: Double){
        if !currentTime.isNaN && !currentTime.isInfinite && !totalTime.isNaN && !totalTime.isInfinite {
            var elapsedTime = currentTime
            if delegate?.getStartOverTime() != nil{
                if currentTime > totalTime{
                    elapsedTime = totalTime
                }
            }
            let sliderValue = self.getSliderDuration(currentTime: elapsedTime, totalDuration: totalTime)
            let remainingTime = totalTime - elapsedTime
            let totalTimeText = ("\(remainingTime.getTimeInString())")
            let currentTimeText = elapsedTime.getTimeInString()
            DispatchQueue.main.async {
                self.totalDurationLabel.text = totalTimeText
                self.elapsedDurationLabel.text = currentTimeText
                self.elapsedDurationLabel.sizeToFit()
                self.elapsedDurationLabel.backgroundColor = .clear
                self.totalDurationLabel.backgroundColor = .clear
                self.sliderView.value = Float(sliderValue)
                self.updateLabelPosition()
//                self.removeTrickPlayView()
            }


        }
    }
        
    
    func updateCurrentTime(currentTime: Double, totalTime: Double){
        debugPrint("updateCurrentTime currentTime \(currentTime) totalTime \(totalTime)")
        if sliderView._isTracking {
            return
        }
        if let pendingPosition = pendingSliderSeekPosition {
            guard abs(currentTime - pendingPosition) <= 1 else {
                return
            }
            pendingSliderSeekPosition = nil
        }
        updateChapteringCuePointsIfNeeded(duration: totalTime)
        switch currentControlsType {
        case .videoStream:
            updateTimeForVideoStream(currentTime: currentTime, totalTime: totalTime)
        case .live(let isDVR):
            if isDVR{
                updateTimeForDVR(currentTime: currentTime, totalTime: totalTime)
            }else{
                updateTimeForLive(currentTime: currentTime)
            }
        }

    }
    
    private func getSliderDuration(currentTime: Double, totalDuration: Double) -> Double {
        guard totalDuration > 0, currentTime <= totalDuration else {return 0}
        return Double(currentTime/totalDuration)
    }

    func videoFinishedPlaying(totalTime: Double?){
        guard let totalTime else{return}

    }

    func didFrameChanged(isFullScreen: Bool){
        self.isFullScreen = isFullScreen
    }
    func playPause(isPlaying: Bool){
        let imageName = isPlaying ? "play_newUI" : "pause_newUI"
        updatePlayPauseVisual(imageNamed: imageName)
        if isPlaying {
            showPlayVideoImage()
        }
    }

    private  func updateTimeForDVR(currentTime: Double, totalTime: Double){
        if !currentTime.isNaN && !currentTime.isInfinite && !totalTime.isNaN && !totalTime.isInfinite{
            sliderView.isUserInteractionEnabled = true
            liveButton.isUserInteractionEnabled = true
            totalDurationLabel.isHidden = true
            elapsedDurationLabel.isHidden = false
            if isChapteringCuePointEnable {
                updateChapteringDVRTime(currentTime: currentTime, totalTime: totalTime)
            } else {
                elapsedDurationLabel.text = currentTime.getTimeInString()
                let sliderValue = getSliderDuration(currentTime: currentTime, totalDuration: totalTime)
                sliderView.value = Float(sliderValue)
            }
            updateLabelPosition()
        }else{
            elapsedDurationLabel.isHidden = true
            totalDurationLabel.isHidden = true
        }
    
    }
#if os(tvOS)
    private func addFocusGuideToControlsStackView(){
        let focusGuide = UIFocusGuide()
        addLayoutGuide(focusGuide)
        focusGuide.trailingAnchor.constraint(equalTo: controlsStackView.trailingAnchor).isActive = true
        focusGuide.bottomAnchor.constraint(equalTo: controlsStackView.bottomAnchor).isActive = true
        focusGuide.topAnchor.constraint(equalTo: controlsStackView.topAnchor).isActive = true
        focusGuide.leadingAnchor.constraint(equalTo: controlsStackView.leadingAnchor).isActive = true
        focusGuide.preferredFocusEnvironments = [slowMoButton, subTitleButton, settingButton]
       focusGuide.visualizeFocusGuide(in: self, color: .purple)
    }
    
    private func addFocusGuideToLiveStackView1(){
        let focusGuide = UIFocusGuide()
        addLayoutGuide(focusGuide)
        focusGuide.leadingAnchor.constraint(equalTo: liveButton.trailingAnchor, constant: 100).isActive = true
        focusGuide.centerYAnchor.constraint(equalTo: liveButton.centerYAnchor, constant: 0).isActive = true
        focusGuide.widthAnchor.constraint(equalToConstant: liveButton.frame.width).isActive = true
        focusGuide.heightAnchor.constraint(equalToConstant: 100).isActive = true
        focusGuide.preferredFocusEnvironments = [slowMoButton, subTitleButton, settingButton]
        toSlowMoButtonTopFocusGuide = focusGuide
        focusGuide.visualizeFocusGuide(in: self, color: .lightGray)
    }
      
    private func addFocusGuideToLiveStackView2(){
        let focusGuide = UIFocusGuide()
        addLayoutGuide(focusGuide)
        focusGuide.leadingAnchor.constraint(equalTo: slowMoButton.leadingAnchor, constant: 0).isActive = true
        focusGuide.centerYAnchor.constraint(equalTo: liveButton.centerYAnchor, constant: 0).isActive = true
        focusGuide.heightAnchor.constraint(equalToConstant: 100).isActive = true
        focusGuide.trailingAnchor.constraint(equalTo: liveButton.superview!.trailingAnchor, constant: 100).isActive = true
        focusGuide.preferredFocusEnvironments = [liveButton]
        toLiveButtonTopFocusGuide = focusGuide
        focusGuide.visualizeFocusGuide(in: self, color: .red)
    }
    #endif
}

#if os(tvOS)
extension VLCustomPlayerControlsView {

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        coordinator.addCoordinatedFocusingAnimations { _ in
            if let focusedView = context.nextFocusedView{
                // Chapter collection cells manage their own focused appearance via
                // the collection view's focus delegate (see +ChapteringSupport).
                if self.isChapteringCuePointEnable, let cv = self.chapteringCollectionView, focusedView.isDescendant(of: cv) {
                } else if [self.settingButton, self.subTitleButton, self.slowMoButton].contains(focusedView) {
                    focusedView.addCustomFocus(withBorder: true)
                }else if focusedView == self.startFromBeginingButton{
                    focusedView.transform = .init(scaleX: 1.1, y: 1.1)
                }
                else if focusedView != self.sliderView && !focusedView.isKind(of: OptionsTableViewCell.self){
                    focusedView.addFocus(withBorder: true)
                }
                else if focusedView == self.sliderView{
                    focusedView.transform = .init(scaleX: 1, y: 1)
                }
            }
        }

        coordinator.addCoordinatedUnfocusingAnimations { _ in
            if let focusedView = context.previouslyFocusedView, focusedView != context.nextFocusedView {
                self.scrollToTop(focusedView: focusedView)
                if self.isChapteringCuePointEnable, let cv = self.chapteringCollectionView, focusedView.isDescendant(of: cv) {
                } else if [self.settingButton, self.subTitleButton, self.slowMoButton].contains(focusedView) {
                    focusedView.removeCustomFocus()
                }else if focusedView == self.startFromBeginingButton{
                    focusedView.transform = .identity
                }else if focusedView != self.sliderView && !focusedView.isKind(of: OptionsTableViewCell.self){
                    focusedView.removeFocus()
                }else if focusedView == self.sliderView{
                    focusedView.transform = .identity
                }
            }
        }
    }
    
    private func scrollToTop(focusedView: UIView){
        if !focusedView.isDescendant(of: self) {
           
        }
    }
}
#endif
extension Numeric{
    func toString() -> String{
        return String(describing: self)
    }
}
extension VLCustomPlayerControlsView{
    
    private func shouldShowSettingOption() -> Bool{
        return true
    }
    
    private func shouldShowSubtitleOption() -> Bool{
        getCloseCaptionList()
        getAudioLanguageList()
        
        return true
    }
    
    
    func createSubTitlesData(type: MenuType) -> PlayerMenuModel{
        let userDefaults = UserDefaults.standard
        var availableSubtitlesMenu = [MenuModel]()
        if let optionsList = getCloseCaptionList(), !optionsList.isEmpty{
            var optionModelList = [Option]()
            for name in optionsList{
                optionModelList.append(Option(name: name))
            }
            optionModelList.insert(Option(name: "off"), at: 0)
            let selectedOption = userDefaults.string(forKey: "closedcaption") ?? "of"
            availableSubtitlesMenu.append(MenuModel(name: .closedCaptions, options: optionModelList, selectedOption: selectedOption))

        }
        //        let closedCaptionOptions = [Option(name: "On"), Option(name: "Off")]
        //        let selectedClosedCaption = userDefaults.string(forKey: SubtitleMenu.closedCaptions.rawValue) ?? "On"
        //        availableSubtitlesMenu.append(MenuModel(name: .closedCaptions, options: closedCaptionOptions, selectedOption: selectedClosedCaption))

        if let optionsList = getAudioLanguageList(), !optionsList.isEmpty{
            var optionModelList = [Option]()
            for name in optionsList{
                optionModelList.append(Option(name: name))
            }
            let selectedOption = userDefaults.string(forKey: SubtitleMenu.audioLanguage.rawValue) ?? optionsList[0]
            availableSubtitlesMenu.append(MenuModel(name: .audioLanguage, options: optionModelList, selectedOption: selectedOption))

        }
        if let optionsList = getCloseCaptionList(), !optionsList.isEmpty, !isCaptionEmbedded {
            let optionsList = FontStyleValues.allCases.map({$0.size})
            var optionModelList = [Option]()
            for name in optionsList{
                optionModelList.append(Option(name: name))
            }
            var selectedOption = optionsList[0]
            if let rawValue = UserDefaults.standard.string(forKey: SubtitleMenu.fontStyles.rawValue), let size = FontStyleValues(rawValue: rawValue)?.size{
                selectedOption = size
            }
            availableSubtitlesMenu.append(MenuModel(name: .fontStyles, options: optionModelList, selectedOption: selectedOption))

        }

        return PlayerMenuModel(type: type, menuModel: availableSubtitlesMenu)


    }
    
    
    func getAudioLanguageList() -> [String]?{
        return delegate?.getAllContentAudioLanguageList()
    }
    func getCloseCaptionList() -> [String]?{
        return delegate?.getAllClosedCaptionList()
    }
#if os(tvOS)
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            let type = press.type
            switch type{
            case .playPause:
                super.pressesBegan(presses, with: event)
            case .select:
                self.delegate?.didTogglePlayPause()
                break
            case .menu:
               
                break
            default:
                super.pressesBegan(presses, with: event)
            }
        }
    }
    
    #endif

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
  
        
        
        debugPrint("Touches Began")
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
  
        debugPrint("Touches Moved")
    }

//    func resetViews() {
//        playerControlsView.isHidden = true
//        showPlayerControls()
//        if optionView != nil{
//            optionView?.removeFromSuperview()
//            optionView = nil
//        }
//    }
    
    func resetViewsWhenControlsHide() {
        playerControlsView.isHidden = false
        playerControlsStackView.isHidden = false
        playerControlsStackView.alpha = 1.0
        gradientView.isHidden = false
#if os(tvOS)
        if optionView != nil{
            optionView?.removeFromSuperview()
            optionView = nil
        }
#endif
    }
    
    func setState(){

    }
    func showPlayerControls(){
        playerControlsStackView.isHidden = false
        playerControlsStackView.alpha = 1.0
        gradientView.isHidden = false
    }
    func showPlayVideoImage(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){[weak self] in
            //  if self?.isPlaying ?? false{
            self?.playPauseImageView?.isHidden = true
            // }
        }
    }
}
extension VLCustomPlayerControlsView {

    func createSettingsData(type: MenuType) -> PlayerMenuModel{
        var availableSubtitlesMenu = [MenuModel]()

        if let optionsList = getVideoPlaybackQualityList(), !optionsList.isEmpty{
            var optionModelList = [Option]()
            let userDefaults = UserDefaults.standard
            for name in optionsList{
                optionModelList.append(Option(name: name))//.replacingOccurrences(of: "p", with: "")))
            }
            let selectedOption = userDefaults.string(forKey: SubtitleMenu.videoQuality.rawValue) ?? optionsList[0]
            availableSubtitlesMenu.append(MenuModel(name: .videoQuality, options: optionModelList, selectedOption: selectedOption))

        }
        
        if let audioList = getAudioPlaybackList(), !audioList.isEmpty {
            var optionModelList = [Option]()
            let userDefaults = UserDefaults.standard
            for name in audioList{
                optionModelList.append(Option(name: name))
            }
            let selectedOption = userDefaults.string(forKey: SubtitleMenu.audioLanguage.rawValue) ?? audioList[0]
            availableSubtitlesMenu.append(MenuModel(name: .audioLanguage, options: optionModelList, selectedOption: selectedOption))
        }

        return PlayerMenuModel(type: type, menuModel: availableSubtitlesMenu)


    }

    func getAudioPlaybackList() -> [String]? {
        return delegate?.getAllContentAudioLanguageList()
    }
    
    func getVideoPlaybackQualityList() -> [String]?{
        return delegate?.getAllVideoPlaybackQualityList()
    }

}

#if os(tvOS)
extension VLCustomPlayerControlsView: PlayerSettingViewDelegate_tvOS {

    func closedCaptionsSelected(name: String, index: Int) {
        delegate?.setClosedCaption(selectedKey: name, selectedIndex: index)
    }
    
//    func updateCaptionsSelected(name: String, index: Int) {
//        player.updateCaption(selectedIndex: index, selectedKey: name)
//    }

    func audioLanguageSelected(name: String) {
        delegate?.setAudioSelected(selectedAudio: name)
    }

    func fontStylesSelected(name: String) {
       delegate?.setCCFontSize()
    }

    func audioQualitySelected(name: String) {
        delegate?.setPlaybackQuality(playbackQuality: name)
    }

    func dismissSettingView() {
        optionView?.removeFromSuperview()
        optionView = nil
        playerControlsStackView.alpha = 1.0
        setChapteringCollectionHidden(false)
        gradientView.isHidden = false
    }

}

extension VLCustomPlayerControlsView {
    func setCuePointsFromPlayer(adModel adsModel: SSAIAdsModel?, duration: TimeInterval) {
        if let adsModel, let avails = adsModel.avails, avails.isEmpty == false {
            var adModelStarTime: [Double] = [Double]()
            for adModel in avails {
                if let adsDuration = adModel.adsDuration, adsDuration > 0, let adStartTime = adModel.startTimeDuration {
                    if adModel.adsDuration != nil, let adStartTime = adModel.startTimeDuration {
                        adModelStarTime.append(adStartTime)
                    }
                }
            }
            self.sliderView.setCuePoints(cuePoints: adModelStarTime, duration: duration)
        }
    }
}
#endif


enum SubtitleMenu: String {
    case closedCaptions = "Closed Captions"
    case audioLanguage = "Audio Language"
    case fontStyles = "fontStyle"
    case videoQuality = "Video Quality"
}

struct MenuModel {
    let name: SubtitleMenu
    var options: [Option]
    var selectedOption: String
}

struct PlayerMenuModel {
    let type: MenuType
    var menuModel: [MenuModel]
}

struct Option {
    let name: String
}

enum MenuType: String {
    case setting = "Settings"
    case subtitle = "Subtitles"
    //case fullScreen = "fullScreenTvOS"
}


extension UIView {

    func aspectRatio(_ ratio: CGFloat) -> NSLayoutConstraint {

        return NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: self, attribute: .width, multiplier: ratio, constant: 0)
    }
}
extension UIFocusGuide {
    func visualizeFocusGuide(in view: UIView, color: UIColor? = .blue) {
        return
        let debugView = UIView()
        let randomColor = UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 0.2
        )
        debugView.backgroundColor = color?.withAlphaComponent(0.2) ?? randomColor
        debugView.layer.borderColor = randomColor.cgColor
        debugView.layer.borderWidth = 2.0
        view.addSubview(debugView)
        debugView.isUserInteractionEnabled = false
        debugView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            debugView.topAnchor.constraint(equalTo: self.topAnchor),
            debugView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            debugView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            debugView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
}

extension UIView {
    /// Returns true if this view or any of its subviews (recursively) is hidden.
    func containsHiddenSubview() -> Bool {
        if self.isHidden {
            return true
        }
        for subview in subviews {
            if subview.containsHiddenSubview() {
                return true
            }
        }
        return false
    }
}


extension Double{
    
    func getTimeInString() -> String {
        var timeString: String = ""
        if !self.isInfinite && !self.isNaN {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .positional
            
            if let formattedText = formatter.string(from: TimeInterval(self)) {
                timeString = formattedText
                if !timeString.contains(":") {
                    if self >= 10 {
                        timeString = "00:\(timeString)"
                    } else {
                        timeString = "00:0\(timeString)"
                    }
                }
            }
        }
        return timeString
    }
    
}

extension UIView {
    
    func addFocus(withBorder: Bool, withScale: Bool = true, andScale: CGFloat = 1.1, withColor: UIColor? = .white, borderRadius: CGFloat = 0) {
        if withScale {
            UIView.animate(withDuration: 0.2, delay: 0) {
                self.transform = .init(scaleX: andScale, y: andScale)
                if withBorder {
                    self.layer.borderColor = withColor?.cgColor
                    self.layer.borderWidth = 4.0
                    if borderRadius != 0 {
                        self.layer.cornerRadius = borderRadius
                    }
                }
            }
        } else {
            if withBorder {
                self.layer.borderColor = withColor?.cgColor
                self.layer.borderWidth = 4.0
                if borderRadius != 0 {
                    self.layer.cornerRadius = borderRadius
                }
            }
        }
    }
    func addCustomFocus(withBorder: Bool, andScale: CGFloat = 1.1, withColor: UIColor = .white) {
        UIView.animate(withDuration: 0.2, delay: 0) {
            self.transform = .init(scaleX: andScale, y: andScale)
            if withBorder {
                self.layer.cornerRadius = 12
                self.layer.backgroundColor = UIColor.fromHex("#212022").cgColor
            }
        }
    }
    func removeCustomFocus() {
        UIView.animate(withDuration: 0.2, delay: 0) {
            self.transform = .identity
            self.layer.cornerRadius = 0
            self.layer.backgroundColor = UIColor.clear.cgColor
        }
    }
    func removeFocus(isPrimary: Bool = false, isSecondary: Bool = false) {
        UIView.animate(withDuration: 0.2, delay: 0) {
            self.transform = .identity
            self.layer.cornerRadius = 0
            
            if isPrimary {
                self.layer.borderColor = UIColor.red.cgColor
                self.layer.borderWidth = 4.0
            } else if isSecondary {
                self.layer.borderColor = UIColor.blue.cgColor
                self.layer.borderWidth = 4.0
            } else {
                self.layer.borderColor = nil
                self.layer.borderWidth = 0
            }
        }
    }
    func round(corners: UIRectCorner, radius: CGFloat) {
        if corners == .allCorners {
            self.layer.cornerRadius = radius
        } else {
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self.layer.mask = mask
            self.layer.needsDisplayOnBoundsChange = true
            self.layer.layoutIfNeeded()
        }
    }
    
    func roundWithBorder(corners: UIRectCorner, radius: CGFloat, borderWidth: CGFloat, borderColor: CGColor) {
        if corners == .allCorners {
            self.layer.cornerRadius = radius
            self.layer.borderColor = borderColor
            self.layer.borderWidth = borderWidth
        } else {
            let path = UIBezierPath(roundedRect: bounds,
                                    byRoundingCorners: corners,
                                    cornerRadii: CGSize(width: radius, height: radius))
            
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            mask.fillColor = nil
            mask.strokeColor = borderColor
            mask.lineWidth = borderWidth
            
            self.layer.addSublayer(mask)
            self.layer.needsDisplayOnBoundsChange = true
        }
        
        self.layer.layoutIfNeeded()
    }
    
}
extension UIView {
    /// Loads a view from a XIB file with the same name as the class
    static func fromNib<T: UIView>() -> T {
        let nibName = String(describing: T.self)
        let bundle = Bundle(for: T.self)
        guard let view = bundle.loadNibNamed(nibName, owner: nil, options: nil)?.first as? T else {
            fatalError("Could not load view from nib file named \(nibName)")
        }
        return view
    }
}

extension UIColor {
    /// Creates a UIColor from a hex string (e.g., "#FF0000" or "FF0000") and optional alpha.
    ///
    /// - Parameters:
    /// - hex: The hex color string.
    /// - alpha: The alpha value (default is 1.0).
    /// - Returns: A UIColor instance.
    static func fromHex(_ hex: String, alpha: CGFloat = 1.0) -> UIColor {
        var cleanedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanedHex.hasPrefix("#") {
            cleanedHex.removeFirst()
        }
        
        guard cleanedHex.count == 6,
              let rgbValue = UInt32(cleanedHex, radix: 16) else {
            return UIColor.white // Fallback for invalid hex
        }
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

#if os(iOS)
extension VLCustomPlayerControlsView: CustomPlayerSkinProtocol{
    
}
#endif
