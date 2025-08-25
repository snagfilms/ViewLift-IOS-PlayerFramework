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
    let actionButton = UIButton(type: .custom)
    var index: Int = 0
    weak var selectionDelegate: SelectionDelegate?
    var isSelected: Bool = false{
        didSet{
            actionButton.isSelected = isSelected
           #if os(tvOS)
            updateImage()
            #endif
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleLabel.numberOfLines = 1
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.textColor = .darkGray

        actionButton.tintColor = .systemBlue
        actionButton.isUserInteractionEnabled = true
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.layer.cornerRadius = 6
        actionButton.clipsToBounds = false

       #if os(iOS)
        titleLabel.font = .systemFont(ofSize: 16)
        let selectedImage = UIImage(systemName: "checkmark.square")
        let unselectedImage = UIImage(systemName: "square")
        actionButton.setImage(selectedImage, for: .selected)
        actionButton.setImage(unselectedImage, for: .normal)
        actionButton.addAction(UIAction { [weak self] _ in
            self?.toggleCheck()
        }, for: .touchUpInside)
       #else
        titleLabel.font = .systemFont(ofSize: 32)
        actionButton.addAction(UIAction { [weak self] _ in
            self?.toggleCheck()
        }, for: .primaryActionTriggered)
       #endif

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
       #if os(tvOS)
        updateImage()
        #endif
        selectionDelegate?.didSelectItem(at: index, selection: actionButton.isSelected)
    }
    #if os(tvOS)
    private func updateImage() {
        let imageName = actionButton.isSelected ? "checkmark.square" : "square"
        let image = UIImage(systemName: imageName)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 40, weight: .regular))
        actionButton.setImage(image, for: .normal)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        if context.nextFocusedView === actionButton {
            coordinator.addCoordinatedAnimations {
                self.actionButton.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }
        } else if context.previouslyFocusedView === actionButton {
            coordinator.addCoordinatedAnimations {
                self.actionButton.transform = .identity
            }
        }
    }
    #endif
}


