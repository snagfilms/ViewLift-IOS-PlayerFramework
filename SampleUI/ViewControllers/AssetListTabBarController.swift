//
//  AssetListTabBarController.swift
//  ViewliftPlayerSampleApp
//
//  Created by Cursor on 29/05/26.
//

import UIKit

final class AssetListTabBarController: UITabBarController {

    private let videoList: VideoList?

    init(videoList: VideoList?) {
        self.videoList = videoList
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.videoList = AppDelegate.shared.readVideoListOperation?.videoList
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewControllers = [
            makeAssetListNavigationController(title: "Assets", imageName: "list.bullet"),
            makeAssetListNavigationController(title: "Assets 2", imageName: "list.bullet.rectangle")
        ]
    }

    private func makeAssetListNavigationController(title: String, imageName: String) -> UINavigationController {
        let assetListViewController = AssetListViewController()
        assetListViewController.videoList = videoList
        assetListViewController.title = title

        let navigationController = UINavigationController(rootViewController: assetListViewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: imageName),
            selectedImage: nil
        )

        return navigationController
    }
}
