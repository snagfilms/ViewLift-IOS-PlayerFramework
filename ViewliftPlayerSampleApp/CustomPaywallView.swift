//
//  CustomPaywallView.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 23/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

class CustomPaywallView: UIView {

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "User does not have a valid TVE subscription"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login with TVE", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    func update(_ message: String) {
        messageLabel.text = message
    }
    
    private func setupViews() {
        addSubview(messageLabel)
        addSubview(actionButton)

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])
    }
}
