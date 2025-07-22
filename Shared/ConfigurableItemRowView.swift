//
//  ConfigurableItemRowView.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 22/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

class ConfigurableItemRowView: UIView {
    let titleLabel = UILabel()
    let actionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .label

        #if os(tvOS)
        actionButton.setTitle("Toggle", for: .normal)
        actionButton.setContentHuggingPriority(.required, for: .horizontal)
        actionButton.adjustsImageWhenHighlighted = false
        #else
        actionButton.setTitle("Toggle", for: .normal)
        #endif

        let stack = UIStackView(arrangedSubviews: [titleLabel, actionButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 8

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
