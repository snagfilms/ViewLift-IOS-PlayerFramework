//
//  ConfigurableItemRowView.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 22/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

protocol SelectionDelegate: AnyObject {
    func didSelectItem(at index: Int, selection: Bool)
}

class ConfigurableItemRowView: UIView {
    let titleLabel = UILabel()
    let actionButton = UIButton(type: .system)
    var index: Int = 0
    weak var selectionDelegate: SelectionDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        titleLabel.numberOfLines = 1
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.textColor = .darkGray
        actionButton.backgroundColor = .clear

        actionButton.setImage(UIImage(systemName: "checkmark.square"), for: .selected)
        actionButton.setImage(UIImage(systemName: "square"), for: .normal)
        actionButton.tintColor = .blue
        actionButton.imageView?.contentMode = .scaleAspectFit
        actionButton.addAction(UIAction { [weak self] _ in
            self?.toggleCheck()
        }, for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionButton.widthAnchor.constraint(equalTo: actionButton.heightAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 44)
        ])

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
    
    private func toggleCheck() {
        actionButton.isSelected.toggle()
        selectionDelegate?.didSelectItem(at: index, selection: actionButton.isSelected)
    }
        
}
