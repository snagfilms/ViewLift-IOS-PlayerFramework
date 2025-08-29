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
    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        iv.layer.borderColor = UIColor.green.cgColor
        iv.layer.borderWidth = 1
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let playButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "play.fill"), for: .normal)
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let countdownLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .white
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .red
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .blue
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // MARK: - Callbacks
    var onPlay: (() -> Void)?
    var onClose: (() -> Void)?
    var onAutoPlay: (() -> Void)?   // when countdown finishes
    
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
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
           return [playButton]   // or [closeButton] if you want close first
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
        addSubview(thumbnailImageView)
        addSubview(playButton)
        addSubview(countdownLabel)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(closeButton)
        
        var constraints: [NSLayoutConstraint] = []
        
        #if os(tvOS)
        // tvOS → Close button on top-left
        constraints.append(contentsOf: [
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)
        ])
        #else
        // iOS → Close button on top-right
        constraints.append(contentsOf: [
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
        #endif
        
        constraints.append(contentsOf: [
            thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            thumbnailImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -40),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 160),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 90),
            
            playButton.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 40),
            playButton.heightAnchor.constraint(equalToConstant: 40),
            
            countdownLabel.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 5),
            countdownLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 15),
            countdownLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: countdownLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 15),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupActions() {
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    // MARK: - Timer Logic
    private func startCountdown() {
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
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
            thumbnailImageView.kf.setImage(with: url)
        } else {
            thumbnailImageView.image = nil
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
        removeFromSuperview()
        onClose?()
    }
}
