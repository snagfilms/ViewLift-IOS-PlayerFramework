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
    private var isExpanded = true

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
        titleLabel.textColor = .black
        arrowButton.setTitle(isExpanded ? "▲" : "▼", for: .normal)
        arrowButton.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)
        arrowButton.isHidden = false
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, arrowButton])
        headerStack.axis = .horizontal
        headerStack.distribution = .fill
        headerStack.alignment = .fill
        headerStack.spacing = 8

        itemsStack.axis = .vertical
        itemsStack.spacing = 0
        itemsStack.alignment = .fill
        itemsStack.distribution = .fill
        itemsStack.isHidden = !isExpanded

        let mainStack = UIStackView(arrangedSubviews: [headerStack, itemsStack])
        mainStack.axis = .vertical
        mainStack.distribution = .fill
        mainStack.alignment = .fill
        mainStack.spacing = 0

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
        for (index, item) in items.enumerated() {
            let row = ConfigurableItemRowView()
            row.index = index
            row.translatesAutoresizingMaskIntoConstraints = false
            row.titleLabel.text = item.type.rawValue
            row.actionButton.isSelected = item.isChecked
            row.selectionDelegate = self
            itemsStack.addArrangedSubview(row)
        }
    }

    var onHeightChanged: (() -> Void)?

    @objc private func toggleExpand() {
        isExpanded.toggle()
        itemsStack.isHidden = !isExpanded
        arrowButton.setTitle(isExpanded ? "▲" : "▼", for: .normal)
        onHeightChanged?()
    }
    
    func getConfigurableItemSelection(type: ConfigurableItemType) -> Bool{
        return items.first(where: {$0.type == type})?.isChecked ?? false
    }
}

struct ConfigurableItem {
    let type: ConfigurableItemType
    var isChecked: Bool
}

enum ConfigurableItemType: String {
    case guestUser = "Guest User"
    case showCustomControls = "Show Custom Controls"
    case hideControls = "Hide Controls"
    case loopPlay = "Loop Play"
    case autoPlay = "Auto Play"
    case mute = "Mute"
}

extension ConfigurableHeaderView: SelectionDelegate {
    func didSelectItem(at index: Int, selection: Bool) {
        items[index].isChecked = selection
    }
}
