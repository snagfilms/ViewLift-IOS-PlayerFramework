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
        btn.backgroundColor = .black
        btn.layer.borderColor = UIColor.green.cgColor
        btn.layer.borderWidth = 1
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
        btn.tintColor = .white
        #if os(tvOS)
        btn.isUserInteractionEnabled = false //disables focus on tvOS
        #else
        btn.isUserInteractionEnabled = true
        #endif
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let countdownLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private func getMultiplier(_ height: CGFloat) -> CGFloat {
        #if os(tvOS)
        return height * 1.8
        #else
        return height
        #endif
    }
    
    // MARK: - Callbacks
    var onPlay: (() -> Void)?
    var onClose: (() -> Void)?
    var onAutoPlay: (() -> Void)?
    
    // MARK: - Timer
    private var timer: Timer?
    private var secondsRemaining: Int = 10
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        setupUI()
        setupActions()
    }
    
   #if os(tvOS)
//    override var preferredFocusEnvironments: [UIFocusEnvironment] {
//            return [closeButton, thumbnailButton]
//
//    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
//        thumbnailButton.isUserInteractionEnabled = true
//        closeButton.isUserInteractionEnabled = true
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
        
        // Thumbnail stack (thumbnail + play overlay)
        let thumbnailContainer = UIView()
        thumbnailContainer.translatesAutoresizingMaskIntoConstraints = false
        thumbnailContainer.addSubview(thumbnailButton)
        thumbnailContainer.addSubview(playButton)
        
        NSLayoutConstraint.activate([
            thumbnailButton.leadingAnchor.constraint(equalTo: thumbnailContainer.leadingAnchor),
            thumbnailButton.trailingAnchor.constraint(equalTo: thumbnailContainer.trailingAnchor),
            thumbnailButton.topAnchor.constraint(equalTo: thumbnailContainer.topAnchor),
            thumbnailButton.bottomAnchor.constraint(equalTo: thumbnailContainer.bottomAnchor),
            
            thumbnailButton.widthAnchor.constraint(equalToConstant: getMultiplier(160)),
            thumbnailButton.heightAnchor.constraint(equalToConstant: getMultiplier(90)),
            
            playButton.centerXAnchor.constraint(equalTo: thumbnailButton.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: thumbnailButton.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: getMultiplier(40)),
            playButton.heightAnchor.constraint(equalToConstant: getMultiplier(40))
        ])
        
        // Labels vertical stack
        let labelsStack = UIStackView(arrangedSubviews: [countdownLabel, titleLabel, subtitleLabel])
        labelsStack.axis = .vertical
        labelsStack.alignment = .leading
        labelsStack.spacing = 6
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Main horizontal stack (thumbnail + labels)
        let mainStack = UIStackView(arrangedSubviews: [thumbnailContainer, labelsStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 15
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(mainStack)
        addSubview(closeButton)
        closeButton.backgroundColor = .purple.withAlphaComponent(0.5)
        // Close button constraints
        #if os(tvOS)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 220),
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 200),
            closeButton.heightAnchor.constraint(equalToConstant: 200),
        ])
        #else
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
        ])
        #endif
        
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -40),
        ])
        
        // Fonts
        countdownLabel.font = UIFont.systemFont(ofSize: getMultiplier(14))
        titleLabel.font = UIFont.systemFont(ofSize: getMultiplier(16), weight: .bold)
        subtitleLabel.font = UIFont.systemFont(ofSize: getMultiplier(16), weight: .semibold)
        // Remove padding
        closeButton.contentEdgeInsets = .zero
        closeButton.imageEdgeInsets = .zero
        closeButton.titleEdgeInsets = .zero

        // Make image fill the button
        closeButton.imageView?.contentMode = .scaleAspectFill
        closeButton.imageView?.clipsToBounds = true
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
        secondsRemaining = 10
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
            onAutoPlay?()
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
        onPlay?()
    }
    
    @objc private func closeTapped() {
        stopCountdown()
        onClose?()
    }
    
#if os(tvOS)
override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
    super.didUpdateFocus(in: context, with: coordinator)
    
    // Thumbnail focus handling
    if let nextFocused = context.nextFocusedView, nextFocused == thumbnailButton {
        coordinator.addCoordinatedAnimations({
            self.thumbnailButton.layer.borderWidth = 4
            self.thumbnailButton.layer.borderColor = UIColor.systemGreen.cgColor
        })
    } else if let previouslyFocused = context.previouslyFocusedView, previouslyFocused == thumbnailButton {
        coordinator.addCoordinatedAnimations({
            self.thumbnailButton.layer.borderWidth = 0
        })
    }
    
    // Close button focus handling
    if let nextFocused = context.nextFocusedView, nextFocused == closeButton {
        coordinator.addCoordinatedAnimations({
            self.closeButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.closeButton.tintColor = .systemRed
        })
    } else if let previouslyFocused = context.previouslyFocusedView, previouslyFocused == closeButton {
        coordinator.addCoordinatedAnimations({
            self.closeButton.transform = .identity
            self.closeButton.tintColor = .white
        })
    }
}
#endif

}
