//
//  ConfigurableHeaderView.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 22/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

class ConfigurableHeaderView: UIView {
    private let titleLabel = UILabel()
    private let arrowButton = UIButton(type: .system)
    private let itemsStack = UIStackView()
    private var isExpanded = false

    private var items: [ConfigurableItem] = []

    init(items: [ConfigurableItem]) {
        self.items = items
        super.init(frame: .zero)
        setupUI()
        populateItems()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        titleLabel.text = "Configurable Items"
        titleLabel.font = .boldSystemFont(ofSize: 16)
        arrowButton.setTitle("▼", for: .normal)
        arrowButton.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, arrowButton])
        headerStack.axis = .horizontal
        headerStack.distribution = .fill
        headerStack.alignment = .center
        headerStack.spacing = 8

        itemsStack.axis = .vertical
        itemsStack.spacing = 8
        itemsStack.isHidden = true

        let mainStack = UIStackView(arrangedSubviews: [headerStack, itemsStack])
        mainStack.axis = .vertical
        mainStack.spacing = 8

        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    private func populateItems() {
        itemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for item in items {
            let row = ConfigurableItemRowView()
            row.titleLabel.text = item.title
            row.actionButton.isSelected = item.isChecked
            itemsStack.addArrangedSubview(row)
        }
    }

    @objc private func toggleExpand() {
        isExpanded.toggle()
        itemsStack.isHidden = !isExpanded
        arrowButton.setTitle(isExpanded ? "▲" : "▼", for: .normal)
    }
}

struct ConfigurableItem {
    let title: String
    var isChecked: Bool
}
