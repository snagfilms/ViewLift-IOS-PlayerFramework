//
//  AutoPlayView.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 27/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import UIKit
import VLPlayerLib
import Kingfisher

class AutoPlayView: UIView {
    
    // MARK: - UI Elements
    private let thumbnailButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.backgroundColor = .clear
        btn.translatesAutoresizingMaskIntoConstraints = false
       #if os(tvOS)
        btn.isUserInteractionEnabled = true
       #else
        btn.isUserInteractionEnabled = false
       #endif
        return btn
    }()
    
    private let playButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "play.fill"), for: .normal)
       #if os(tvOS)
        btn.isUserInteractionEnabled = false //disables focus on tvOS
        #else
        btn.isUserInteractionEnabled = true
        #endif
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.contentVerticalAlignment = .fill
        btn.contentHorizontalAlignment = .fill
        btn.imageView?.contentMode = .scaleAspectFit

        return btn
    }()
    
    private let countdownLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.contentVerticalAlignment = .fill
        btn.contentHorizontalAlignment = .fill
        btn.imageView?.contentMode = .scaleAspectFit
        btn.contentEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        return btn
    }()
    
    private func getMultiplier(_ height: CGFloat) -> CGFloat {
#if os(tvOS)
        return height * 1.8
#else
        return height
#endif
    }
    
    var autoPlayUICallback:((_ shouldAutoPlayNextVideo:Bool) -> Void)?
    
    // MARK: - Timer
    private var timer: Timer?
    private var secondsRemaining: Int
    private var autoPlayTimerCount: Int
    private let theme: VLPlayer.AutoPlayTheme
    // MARK: - Init
    init(theme: VLPlayer.AutoPlayTheme,autoPlayTimerCount: Int) {
        self.theme = theme
        self.autoPlayTimerCount = autoPlayTimerCount
        self.secondsRemaining = autoPlayTimerCount
        super.init(frame: .zero)
        setupUI()
        setupActions()
        setupTheme()
    }
    
    private func setupTheme(){
        self.backgroundColor = theme.backgroundColor
        setThumbnailUnFocusedBorder()
        setCloseButtonUnFocusedBorder()
        countdownLabel.font = theme.timerText.font
        titleLabel.font = theme.title.font
        subtitleLabel.font = theme.description.font
        countdownLabel.textColor = theme.timerText.textColor
        subtitleLabel.textColor = theme.description.textColor
        titleLabel.textColor = theme.title.textColor
        playButton.tintColor = theme.iconTint
        closeButton.tintColor = theme.iconTint
    }
    
#if os(tvOS)
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [thumbnailButton]
        
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

    }
#endif
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopCountdown()
    }
    
    // MARK: - Setup
    private func setupUI() {
        let width = UIScreen.main.bounds.width
        let thumbnailWidth = width * 0.4
        let thumbnailHeight = thumbnailWidth * 9.0 / 16.0
        // Thumbnail stack (thumbnail + play overlay)
        var stackViewLabelSpace: CGFloat = 10
        var stackViewHorizontalSpace: CGFloat = 50
        var bottomSpace: CGFloat = 50
        #if os(iOS)
        stackViewLabelSpace = 5
        stackViewHorizontalSpace = 10
        bottomSpace = 10
        #endif
        let thumbnailContainer = UIView()
        thumbnailContainer.translatesAutoresizingMaskIntoConstraints = false
        thumbnailContainer.addSubview(thumbnailButton)
        thumbnailContainer.addSubview(playButton)
        
        NSLayoutConstraint.activate([
            // Thumbnail fills its container
            thumbnailButton.topAnchor.constraint(equalTo: thumbnailContainer.topAnchor),
            thumbnailButton.leadingAnchor.constraint(equalTo: thumbnailContainer.leadingAnchor),
            thumbnailButton.trailingAnchor.constraint(equalTo: thumbnailContainer.trailingAnchor),
            thumbnailButton.bottomAnchor.constraint(equalTo: thumbnailContainer.bottomAnchor),

           // thumbnailContainer.widthAnchor.constraint(equalToConstant: getMultiplier(320)),
            //thumbnailContainer.heightAnchor.constraint(equalToConstant: getMultiplier(180)),
            thumbnailContainer.widthAnchor.constraint(equalToConstant: thumbnailWidth),
                thumbnailContainer.heightAnchor.constraint(equalToConstant: thumbnailHeight),
            // Play button centered on container
            playButton.widthAnchor.constraint(equalToConstant: getMultiplier(40)),
            playButton.heightAnchor.constraint(equalToConstant: getMultiplier(40)),
            playButton.centerXAnchor.constraint(equalTo: thumbnailContainer.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: thumbnailContainer.centerYAnchor)
        ])

        
        // Labels vertical stack
        let labelsStack = UIStackView(arrangedSubviews: [countdownLabel, titleLabel, subtitleLabel])
        labelsStack.axis = .vertical
        labelsStack.alignment = .leading
        labelsStack.spacing = stackViewLabelSpace
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Main horizontal stack (thumbnail + labels)
        let mainStack = UIStackView(arrangedSubviews: [thumbnailContainer, labelsStack])
        mainStack.axis = .horizontal
        mainStack.spacing = stackViewHorizontalSpace
        mainStack.alignment = .bottom
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(mainStack)
        addSubview(closeButton)
        // Close button constraints
#if os(tvOS)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 40),
            closeButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 40),
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 60),
        ])
#else
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
        ])
#endif
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -bottomSpace)
        ])
        
        
        // Make image fill the button
        closeButton.imageView?.contentMode = .scaleAspectFill
        closeButton.imageView?.clipsToBounds = true
        titleLabel.numberOfLines = 2
        subtitleLabel.numberOfLines = 2
        countdownLabel.numberOfLines = 2
    }
    
    private func setThumbnailUnFocusedBorder(){
        thumbnailButton.layer.borderWidth = 1
        thumbnailButton.layer.borderColor = theme.thumbnailBorderColor.cgColor
    }
    
    private func setCloseButtonUnFocusedBorder(){
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = theme.closeButtonBorderColor.cgColor
    }
    
    private func setupActions() {
#if os(iOS)
        thumbnailButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
#else
        thumbnailButton.addTarget(self, action: #selector(playTapped), for: .primaryActionTriggered)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .primaryActionTriggered)
#endif
    }
    
    // MARK: - Timer
    private func startCountdown() {
        stopCountdown()
        secondsRemaining = self.autoPlayTimerCount
        updateCountdownLabel()
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(updateTimer),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    private func stopCountdown() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func updateTimer() {
        secondsRemaining -= 1
        updateCountdownLabel()
        
        if secondsRemaining <= 0 {
            stopCountdown()
            autoPlayUICallback?(true)
        }
    }
    
    func updateView(data: VLPlayer.ContentData?) {
        stopCountdown()
        titleLabel.text = data?.contentTitle
        subtitleLabel.text = data?.contentDescription
        if let urlString = data?.thumbnail, let url = URL(string: urlString) {
            thumbnailButton.kf.setImage(with: url, for: .normal)
        } else {
            thumbnailButton.setImage(nil, for: .normal)
        }
        startCountdown()
    }
    
    private func updateCountdownLabel() {
        countdownLabel.text = "Next Video will play in \(secondsRemaining) seconds"
    }
    
    // MARK: - Actions
    @objc private func playTapped() {
        stopCountdown()
        autoPlayUICallback?(true)
    }
    
    @objc private func closeTapped() {
        stopCountdown()
        autoPlayUICallback?(false)
    }
    
#if os(tvOS)
    private func setThumbnailFocusedBorder(){
        thumbnailButton.layer.borderWidth = 4
        thumbnailButton.layer.borderColor = theme.focusBorderColor.cgColor
    }
    
    private func setCloseButtonFocusedBorder(){
        closeButton.layer.borderWidth = 4
        closeButton.layer.borderColor = theme.focusBorderColor.cgColor
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        // Thumbnail focus handling
        if let nextFocused = context.nextFocusedView, nextFocused == thumbnailButton {
            coordinator.addCoordinatedAnimations({
                self.setThumbnailFocusedBorder()
            })
        } else if let previouslyFocused = context.previouslyFocusedView, previouslyFocused == thumbnailButton {
            coordinator.addCoordinatedAnimations({
                self.setThumbnailUnFocusedBorder()
            })
        }
        
        // Close button focus handling
        if let nextFocused = context.nextFocusedView, nextFocused == closeButton {
            coordinator.addCoordinatedAnimations({
                self.closeButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                self.setCloseButtonFocusedBorder()
            })
        } else if let previouslyFocused = context.previouslyFocusedView, previouslyFocused == closeButton {
            coordinator.addCoordinatedAnimations({
                self.closeButton.transform = .identity
                self.setCloseButtonUnFocusedBorder()
            })
        }
    }
#endif
    
}
