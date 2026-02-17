//
//  InfoViewController.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 17/02/26.
//  Copyright © 2026 Viewlift. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [closeButton] // or first focusable item
    }

    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome to the Player SDK"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text =
        """
        This is a sample description text for demonstration purposes.
        It explains how the SDK behaves and gives some example content.
        You can replace this text with whatever you need.
        """
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private var closeButton: UIButton = {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        return closeButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black.withAlphaComponent(0.7)

        setupUI()
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            // Title at top (safe area)
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Description below title
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
        closeButton.addTarget(self, action: #selector(closeTapped), for: .primaryActionTriggered)

    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        
    }
    
    @objc func closeTapped() {
        dismiss(animated: true)
    }
}
