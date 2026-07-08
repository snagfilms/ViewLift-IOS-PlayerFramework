//
//  AssetTableViewCell.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 22/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

protocol AssetTableViewCellDelegate: AnyObject {
    func assetCellDidTapInfo(_ cell: AssetTableViewCell, asset: AssetModel)
}

class AssetTableViewCell: UITableViewCell {
    static let reuseIdentifier = "AssetCell"

    private let leftIndexLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let infoButton = UIButton(type: .infoLight)
    private let separatorView = UIView()
    private var assetModel: AssetModel?

    weak var delegate: AssetTableViewCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        #if os(iOS)
        setupDarkModeSupport()
        #endif
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    #if os(iOS)
    // MARK: - Dark Mode Support
    
    private func setupDarkModeSupport() {
        // Cell background colors that adapt to dark mode
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground
        
        // Configure selected background view
        let selectedView = UIView()
        selectedView.backgroundColor = .systemGray4
        selectedBackgroundView = selectedView
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Update colors when appearance changes
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColorsForCurrentTraitCollection()
        }
    }
    
    private func updateColorsForCurrentTraitCollection() {
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground
        titleLabel.textColor = .label
        subtitleLabel.textColor = .secondaryLabel
        separatorView.backgroundColor = UIColor.separator.withAlphaComponent(0.6)
    }
#endif

#if os(tvOS)
    // MARK: - tvOS Focus Handling
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        coordinator.addCoordinatedAnimations {
            if self.isFocused {
                // Cell is focused - apply focused state
//                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.layer.shadowColor = UIColor.black.cgColor
                self.layer.shadowOffset = CGSize(width: 0, height: 10)
                self.layer.shadowOpacity = 0.3
                self.layer.shadowRadius = 15
                
                // Apply focus background color
                self.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                self.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                
                self.titleLabel.textColor = .black
                self.subtitleLabel.textColor = UIColor.black.withAlphaComponent(0.8)
                self.leftIndexLabel.textColor = .systemBlue
            } else {
                // Cell is unfocused - revert to normal state
//                self.transform = .identity
                self.layer.shadowOpacity = 0
                
                // Remove focus background color
                self.backgroundColor = .clear
                self.contentView.backgroundColor = .clear
                
                // Revert to semantic text colors (adapt to Light/Dark mode).
                self.titleLabel.textColor = .label
                self.subtitleLabel.textColor = .secondaryLabel
                self.leftIndexLabel.textColor = .systemBlue
            }
        }
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
#endif


    private func setupUI() {
        leftIndexLabel.textColor = .systemBlue
        leftIndexLabel.textAlignment = .center
        leftIndexLabel.setContentHuggingPriority(.required, for: .horizontal)
        leftIndexLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        leftIndexLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.numberOfLines = 0
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textColor = .secondaryLabel
        titleLabel.textColor = .label
       #if os(tvOS)
       leftIndexLabel.font = UIFont.boldSystemFont(ofSize: 32)
       titleLabel.font = UIFont.boldSystemFont(ofSize: 32)
       subtitleLabel.font = UIFont.systemFont(ofSize: 28)
       infoButton.isHidden = true
       backgroundColor = .clear
       contentView.backgroundColor = .clear
       #else
       titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
       subtitleLabel.font = UIFont.systemFont(ofSize: 14)
       leftIndexLabel.font = UIFont.boldSystemFont(ofSize: 16)
       #endif

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        infoButton.setContentHuggingPriority(.required, for: .horizontal)
        infoButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        let horizontalStack = UIStackView(arrangedSubviews: [leftIndexLabel, textStack, infoButton])
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 8
        horizontalStack.alignment = .top
        horizontalStack.distribution = .fill
        contentView.addSubview(horizontalStack)
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            horizontalStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            horizontalStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            horizontalStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            horizontalStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])

        separatorView.backgroundColor = UIColor.separator.withAlphaComponent(0.6)
        contentView.addSubview(separatorView)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    func setSeparatorHidden(_ hidden: Bool) {
        separatorView.isHidden = hidden
    }

    func configure(with asset: AssetModel, index: Int) {
        assetModel = asset
        #if os(tvOS)
        leftIndexLabel.text = "tvOS-PL-UC-\(index + 1)"
        #else
        leftIndexLabel.text = "iOS-PL-UC-\(index + 1)"
        #endif
        titleLabel.text = asset.title
        subtitleLabel.text = asset.subtitle
        subtitleLabel.isHidden = asset.subtitle?.isEmpty ?? true
    }

    @objc private func infoButtonTapped() {
        guard let asset = assetModel else { return }
        delegate?.assetCellDidTapInfo(self, asset: asset)
    }
}
