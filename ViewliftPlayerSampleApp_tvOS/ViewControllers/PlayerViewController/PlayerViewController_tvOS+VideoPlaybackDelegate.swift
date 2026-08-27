//
//  PlayerViewController_tvOS+VideoPlaybackDelegate.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLPlayerLib
import AVKit
import Foundation
import VLAnalyticsLib

// Handle video playback delegate events for the player view controller
extension PlayerViewController_tvOS: VideoPlaybackDelegate {
    
    func onFullScreenChange(currentTime: Double, isFullScreen: Bool, playerTag: String) {
        debugPrint("onFullScreenChange: currentTime: \(currentTime), isFullScreen: \(isFullScreen), playerTag: \(playerTag)")
        testButton.isHidden = isFullScreen
        changeLayout()
    }
    
    func videoPlaybackError(currentTime: Double, errorMessage: String, errorCode: String, playerTag: String) {
        DispatchQueue.main.async { [weak self] in
            self?.loaderView.stopAnimating()
            if let playerView = self?.vlPlayer?.getVideoPlayerView(){
                self?.errorHandler(message: errorMessage, playerView: playerView)
            }
        }
    }
    
    private func errorHandler(message: String, playerView: UIView) {
        let errorLabel = UILabel()
        errorLabel.text = message
        errorLabel.textColor = .white
        errorLabel.textAlignment = .center
        errorLabel.font = .systemFont(ofSize: 32, weight: .medium)
        errorLabel.numberOfLines = 0
        errorLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        errorLabel.layer.cornerRadius = 8
        errorLabel.clipsToBounds = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        playerView.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: playerView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: playerView.trailingAnchor, constant: -20)
        ])
    }

    
    // Handles errors during video fetch and updates UI accordingly
    func videoFetchError(error: VLError?, playerTag: String?, contentResponse: Dictionary<String, AnyObject>?) {
        let errorDescription =  "Is content playable - \(error?.isPlayable ?? false) \n" +
        "Content Fetched successfully - \(error?.isSuccess ?? false) \n" +
        "Error Code - \(error?.errorCode ?? "errorCode") \n" +
        "Error Message - \(error?.errorMessage ?? "errorMessage") \n" +
        "Error VL Code - \(error?.vl_errorCode ?? "errorVLCode")"
        
        print("Error VL:", errorDescription)
        print("VideoFetchError: contentResponse:", contentResponse)
        
        if error?.errorCode == "TVE_SUBSCRIPTION_NOT_FOUND"{// handle other TVE error code too
            loginWithTVE()
        } else {
            DispatchQueue.main.async {
                self.loaderView.stopAnimating()
                self.showAlert(message: errorDescription)
                self.customPaywallView?.update(error?.errorMessage ?? "Error occurred while fetching content")
            }
        }
        
    }
    
    // Updates play/pause state in custom controls
    func customPlayerState(isPlaying: Bool) {
        videoPlayerControlsView?.playPause(isPlaying: isPlaying)
        
    }
    
    // Called when subtitle embedding in URL changes
    func isSubtitlesEmbeddedInUrlChanged(isEmbedded: Bool) {
        debugPrint("PlayerViewController isSubtitlesEmbeddedInUrlChanged: \(isEmbedded)")
    }
 
    func videoFinished(playerTag: String) {
//        AnalyticsHelper.shared.trackVideoCompletedAnalytics()
        
        
    }
    
    // Called when custom player controls visibility changes
    func customPlayerControls(isHidden: Bool) {
        print("PlayerViewController customPlayerControls: \(isHidden)")
        if isHidden{
            videoPlayerControlsView?.customPlayerControls(isHidden: isHidden)
        }
    }
    
    // Called when video playback starts
    func videoStarted(timestamp: Double, playerTag: String, metaDataInfo: [String : Any]?) {
        loaderView.stopAnimating()
        videoPlayerControlsView?.videoStartedPlaying(timestamp: timestamp)
        debugPrint("PlayerViewController videoStarted: \(timestamp)")
        
        self.videoSessionStartAnalytics()
    }
    
    func videoPause(timestamp: Double, playerTag: String) {

    }
    
    func videoResume(timestamp: Double, playerTag: String, metaDataInfo: [String : Any]?) {
        debugPrint("")
    }
    
    func videoSessionStartAnalytics() {

    }
    
    // Updates playback progress every second
    func videoPlayerProgressByEverySecond(currentTime: Double, totalTime: Double, playerTag: String, parsedTimeStamp: String?) {
       // debugPrint("PlayerViewController videoPlayerProgressByEverySecond: \(currentTime), \(totalTime)")
        videoPlayerControlsView?.updateCurrentTime(currentTime: currentTime, totalTime: totalTime)
        
        self.invalidatePlayerTempPassIfOutOfWindow()
    }
    
    // Updates playback progress at specific intervals
    func videoPlayerUpdateByProgressInterveral(currentTime: Double, totalTime: Double, playerTag: String) {
        debugPrint("PlayerViewController videoPlayerUpdateByProgressInterveral]ssByEverySecond: \(currentTime), \(totalTime)")
        videoPlayerControlsView?.updateCurrentTime(currentTime: currentTime, totalTime: totalTime)
    }
    
    func videoPlayerProgressOnDefinedInterval(currentTime: Double, totalTime: Double, playerTag: String) {
        self.updateWatchHistoryDisplay(watchedTime: currentTime, watchedPercentage: (currentTime/totalTime)*100)
    }
    
    // Handles back button tap event
    func onBackButtonTapped() {
        menuPressed()
    }

    /// Forwards the SDK's chapter Schedule button event to the host app.
    func chapterScheduleButtonTapped(playerTag: String) {
        onChapterScheduleButtonTapped?(playerTag)
        presentDummyChapterSchedule()
    }

    private func presentDummyChapterSchedule() {
        guard chapterScheduleViewController == nil else { return }

        let scheduleItems = [
            (time: "8:00 AM", title: "Market Movers"),
            (time: "9:00 AM", title: "Squawk Box"),
            (time: "10:00 AM", title: "Worldwide Exchange"),
            (time: "11:00 AM", title: "Power Lunch"),
            (time: "12:00 PM", title: "Closing Bell"),
            (time: "1:00 PM", title: "Fast Money"),
            (time: "2:00 PM", title: "Closing Bell: Overtime")
        ]

        let scheduleViewController = DummyChapterScheduleViewController(
            scheduleItems: scheduleItems,
            dismissHandler: { [weak self] in
                self?.dismissDummyChapterSchedule()
            }
        )
        scheduleViewController.modalPresentationStyle = .overCurrentContext
        scheduleViewController.modalTransitionStyle = .crossDissolve
        chapterScheduleViewController = scheduleViewController
        definesPresentationContext = true
        present(scheduleViewController, animated: true)
    }

    func dismissDummyChapterSchedule(suppressPlayerDismissal: Bool = false) {
        guard let scheduleViewController = chapterScheduleViewController else { return }
        if suppressPlayerDismissal {
        }
        vlPlayer?.setPlayerControls(isHidden: false)
        chapterScheduleViewController = nil
        scheduleViewController.dismiss(animated: true) { [weak self] in
            self?.setNeedsFocusUpdate()
            self?.updateFocusIfNeeded()
        }
    }
    
    func avPlayerControllerInstance(_ avPlayerControllerInstance: AVPlayerViewController) {
        avPlayerControllerInstance.delegate = self
    }
    
    func adStarted(currentTime: Double, adTag: String?, playerTag: String, player: AVPlayer, metaDataInfo: [String : Any]?) {
        debugPrint("adStarted")
    }
}

extension PlayerViewController_tvOS: AVPlayerViewControllerDelegate {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willResumePlaybackAfterUserNavigatedFrom oldTime: CMTime, to targetTime: CMTime) {
        debugPrint("willResumePlaybackAfterUserNavigatedFrom: oldTime: \(oldTime), targetTime: \(targetTime)")
    }
    
}


//Dummy ChapterScheduleViewController to show the Schedule Data
private final class DummyChapterScheduleViewController: UIViewController {
    private let scheduleItems: [(time: String, title: String)]
    private let dismissHandler: () -> Void
    private let panelView = UIView()
    weak var preferredScheduleFocusView: UIView?

    init(scheduleItems: [(time: String, title: String)], dismissHandler: @escaping () -> Void) {
        self.scheduleItems = scheduleItems
        self.dismissHandler = dismissHandler
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let preferredScheduleFocusView {
            return [preferredScheduleFocusView]
        }
        return super.preferredFocusEnvironments
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) {
            dismissHandler()
            return
        }
        super.pressesBegan(presses, with: event)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        panelView.translatesAutoresizingMaskIntoConstraints = false
        panelView.backgroundColor = UIColor(red: 0.025, green: 0.025, blue: 0.10, alpha: 0.96)
        view.addSubview(panelView)

        let scheduleTab = UIButton(type: .system)
        scheduleTab.setTitle("Schedule", for: .normal)
        scheduleTab.titleLabel?.font = .systemFont(ofSize: 28, weight: .semibold)
        scheduleTab.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        scheduleTab.layer.cornerRadius = 8

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .semibold)
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        closeButton.layer.cornerRadius = 8
        closeButton.addAction(UIAction { [weak self] _ in
            self?.dismissHandler()
        }, for: .primaryActionTriggered)

        let headerStack = UIStackView(arrangedSubviews: [scheduleTab, closeButton])
        headerStack.axis = .horizontal
        headerStack.spacing = 16
        headerStack.distribution = .fillEqually
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Today's Schedule"
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        subtitleLabel.font = .systemFont(ofSize: 22)

        let dateLabel = UILabel()
        dateLabel.text = "May 21, 2026"
        dateLabel.textColor = UIColor(red: 0.35, green: 0.65, blue: 1.0, alpha: 1.0)
        dateLabel.font = .systemFont(ofSize: 32, weight: .bold)

        let titleStack = UIStackView(arrangedSubviews: [subtitleLabel, dateLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 4

        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        rowsStack.spacing = 8
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        var firstScheduleButton: UIButton?
        for item in scheduleItems {
            let button = UIButton(type: .system)
            button.contentHorizontalAlignment = .leading
            button.setTitle("  \(item.time)    \(item.title)", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 24, weight: .semibold)
            button.backgroundColor = UIColor.white.withAlphaComponent(0.06)
            button.layer.cornerRadius = 8
            button.heightAnchor.constraint(equalToConstant: 56).isActive = true
            rowsStack.addArrangedSubview(button)
            if firstScheduleButton == nil {
                firstScheduleButton = button
            }
        }

        preferredScheduleFocusView = firstScheduleButton

        let contentStack = UIStackView(arrangedSubviews: [headerStack, titleStack, rowsStack])
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        panelView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            panelView.topAnchor.constraint(equalTo: view.topAnchor),
            panelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panelView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panelView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.34),
            contentStack.topAnchor.constraint(equalTo: panelView.safeAreaLayoutGuide.topAnchor, constant: 36),
            contentStack.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 38),
            contentStack.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -38)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }
}
