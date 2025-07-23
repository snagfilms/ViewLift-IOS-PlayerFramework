//
//  AssetInfoViewController.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 22/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

class AssetInfoViewController: UIViewController {
    private let asset: AssetModel

    init(asset: AssetModel) {
        self.asset = asset
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }

    private func setupUI() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        closeButton.tintColor = .label
        closeButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = "Title: \(asset.title)"
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Subtitle: \(asset.subtitle ?? "N/A")"
        subtitleLabel.numberOfLines = 0

        let playbackLabel = UILabel()
        playbackLabel.text = {
            switch asset.playbackType {
            case .url(let value): return "Playback: URL - \(value)"
            case .videoId(let value): return "Playback: Video ID - \(value)"
            }
        }()
        playbackLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [closeButton, titleLabel, subtitleLabel, playbackLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .leading

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

}