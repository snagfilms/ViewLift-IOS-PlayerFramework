//
//  Untitled.swift
//  ViewliftPlayerSampleApp
//
//  Created by Jaskirat on 02/01/26.
//  Copyright © 2026 Viewlift. All rights reserved.
//

import UIKit

extension PlayerViewController_iOS: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    internal func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(
            SeekCell.self,
            forCellWithReuseIdentifier: SeekCell.identifier
        )
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: playerContainerView.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return seekOptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SeekCell.identifier,
            for: indexPath
        ) as! SeekCell

        cell.configure(text: seekOptions[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(
            width: collectionView.bounds.width - 32,
            height: 60
        )
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        switch indexPath.item {
        case 0:
            // seek to 5s
            self.vlPlayer?.seekTo(seconds: 5)
        case 1:
            // seek to 10s
            self.vlPlayer?.seekTo(seconds: 10)
        case 2:
            // seek to 20s
            self.vlPlayer?.seekTo(seconds: 20)
        default:
            break
        }
    }
}


final class SeekCell: UICollectionViewCell {

    static let identifier = "SeekCell"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .gray
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)

        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(text: String) {
        titleLabel.text = text
    }
}
