//
//  EmojiGridViewController.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 17/02/26.
//  Copyright © 2026 Viewlift. All rights reserved.
//

import UIKit

final class EmojiGridViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var emojis: [String] = []
    private var lastFocusedIndexPath: IndexPath?
    private var needsFocusUpdate = false
    
    private let rows = 3
    private let itemsPerRow = 33  // Total items per row
    
    private let emojiPool = [
        "😀","😎","🥳","🤩","🚀","🔥","🎮","🎬",
        "🏀","🎵","🌈","🐶","🐱","🦊","🐼","🍎"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black.withAlphaComponent(0.7)
        
        setupEmojis()
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reset focus state when view appears
        needsFocusUpdate = true
        setNeedsFocusUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Ensure focus is set properly after view appears
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }
    
    private func setupEmojis() {
        let totalCells = rows * itemsPerRow
        emojis = (0..<totalCells).map { _ in
            emojiPool.randomElement()!
        }
    }
    
    private func setupCollectionView() {
        let layout = createCompositionalLayout()
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
        collectionView.remembersLastFocusedIndexPath = false
        collectionView.alwaysBounceVertical = false
        
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Calculate and set content inset to center vertically
        let itemHeight: CGFloat = 160
        let rowSpacing: CGFloat = 20
        let totalContentHeight = (itemHeight * CGFloat(rows)) + (rowSpacing * CGFloat(rows - 1))
        let screenHeight = UIScreen.main.bounds.height
        let topInset = max(80, (screenHeight - totalContentHeight) / 2)
        
        collectionView.contentInset = UIEdgeInsets(top: topInset, left: 80, bottom: topInset, right: 80)
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        debugPrint("pressesBegan")
    }

    
    private func createCompositionalLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
            
            let itemWidth: CGFloat = 280
            let itemHeight: CGFloat = 160
            
            // Single item
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(itemWidth),
                heightDimension: .absolute(itemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // Vertical group containing all rows
            let verticalGroupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(itemWidth),
                heightDimension: .absolute(itemHeight * CGFloat(self.rows) + 20 * CGFloat(self.rows - 1))
            )
            let verticalGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: verticalGroupSize,
                subitem: item,
                count: self.rows
            )
            verticalGroup.interItemSpacing = .fixed(20)
            
            // Section
            let section = NSCollectionLayoutSection(group: verticalGroup)
            section.interGroupSpacing = 20 // Horizontal spacing between columns
            
            return section
        }
        
        // Configure main scroll direction
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        layout.configuration = config
        
        return layout
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        // Always prefer the first cell when view is reused
        if needsFocusUpdate {
            needsFocusUpdate = false
            lastFocusedIndexPath = IndexPath(item: 0, section: 0)
        }
        
        if let indexPath = lastFocusedIndexPath,
           let cell = collectionView.cellForItem(at: indexPath) {
            return [cell]
        }
        return [collectionView]
    }
}

// MARK: - UICollectionViewDataSource
extension EmojiGridViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
           return 1 // Single section
       }
       
       func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
           return rows * itemsPerRow // Total items
       }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCell
        
        let emojiIndex = indexPath.section * itemsPerRow + indexPath.item
        cell.configure(with: emojis[emojiIndex])
        
        // Apply correct state based on last focus
        if indexPath == lastFocusedIndexPath {
            cell.applyFocusedState()
        } else {
            cell.applyUnfocusedState()
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension EmojiGridViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        // Animate the previously focused cell back to normal
        if let previousCell = context.previouslyFocusedView as? EmojiCell {
            coordinator.addCoordinatedAnimations({
                previousCell.applyUnfocusedState()
            }, completion: nil)
        }
        
        // Animate the newly focused cell
        if let nextCell = context.nextFocusedView as? EmojiCell,
           let nextIndexPath = context.nextFocusedIndexPath {
            lastFocusedIndexPath = nextIndexPath
            coordinator.addCoordinatedAnimations({
                nextCell.applyFocusedState()
                
                // Scroll to make the focused cell fully visible
                self.collectionView.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)
            }, completion: nil)
        }
    }
}

// MARK: - Custom Cell
final class EmojiCell: UICollectionViewCell {
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 60)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let backgroundContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.backgroundColor = .clear
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(backgroundContainer)
        contentView.addSubview(emojiLabel)
        
        NSLayoutConstraint.activate([
            backgroundContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyUnfocusedState()
    }
    
    func configure(with emoji: String) {
        emojiLabel.text = emoji
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
    
    func applyFocusedState() {
        backgroundContainer.backgroundColor = .systemBlue
        transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
    }
    
    func applyUnfocusedState() {
        backgroundContainer.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        transform = .identity
    }
}
