//
//  RootTabBarController.swift
//  ViewliftPlayerSampleApp
//
//  Copyright © 2026 Viewlift. All rights reserved.
//

import UIKit
import VLPlayerLib

final class RootTabBarController: UITabBarController {

    private let videoList: VideoList
    private let assetIndexes = [0, 2]
    private var loadErrorMessage: String?
    private var didShowLoadError = false

    init(videoList: VideoList) {
        self.videoList = videoList
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("RootTabBarController is created in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = makeTabs()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let loadErrorMessage, didShowLoadError == false else { return }
        didShowLoadError = true
        showAlert(message: loadErrorMessage)
    }

    private func makeTabs() -> [UIViewController] {
        guard let assets = loadAssets() else {
            loadErrorMessage = "Unable to load assets-provider.json."
            return []
        }

        var tabs: [UIViewController] = []
        for index in assetIndexes {
            guard assets.indices.contains(index) else {
                loadErrorMessage = "Missing asset at index \(index)."
                return []
            }
            let asset = assets[index]
            let player = makePlayer(for: asset)
            // #region agent log
            agentBd5c3bSample(
                location: "RootTabBarController.makeTabs",
                message: "tab player created",
                hypothesisId: "H4",
                data: [
                    "assetIndex": index,
                    "title": asset.title,
                    "contentIdentifier": asset.contentIdentifier ?? "",
                    "player": ObjectIdentifier(player).hashValue
                ]
            )
            // #endregion
            let navigationController = UINavigationController(rootViewController: player)
            navigationController.setNavigationBarHidden(true, animated: false)
            navigationController.tabBarItem = UITabBarItem(title: asset.title, image: nil, tag: index)
            tabs.append(navigationController)
        }
        return tabs
    }

    private func makePlayer(for asset: AssetModel) -> PlayerViewController_iOS {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let player = storyboard.instantiateViewController(withIdentifier: "PlayerViewController_iOS") as! PlayerViewController_iOS
        var list = videoList

        switch asset.playbackType {
        case .videoId(let id):
            list.videoId = id
            list.channelId = asset.channelId ?? []
            player.channelId = asset.channelId ?? []
            player.prepareView(withPlayerUIOption: .defaultControl, videoList: list)
        case .url(let url):
            player.streamUrl = url
            player.streamConfig = VLPlayer.StreamConfig(isLive: asset.isLive, isDVR: asset.isDVR)
            player.channelId = asset.channelId ?? []
            player.prepareView(withPlayerUIOption: .playStreamURL, videoList: list)
        }

        player.autoplayEnabled = true
        return player
    }

    private func loadAssets() -> [AssetModel]? {
        guard let url = Bundle.main.url(forResource: "assets-provider", withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([AssetModel].self, from: data)
        } catch {
            return nil
        }
    }

    private func showAlert(title: String = "Alert!", message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

// #region agent log
func agentBd5c3bSample(location: String, message: String, hypothesisId: String, data: [String: Any]) {
    let payload: [String: Any] = [
        "sessionId": "bd5c3b",
        "runId": "post-fix",
        "hypothesisId": hypothesisId,
        "location": location,
        "message": message,
        "data": data,
        "timestamp": Int(Date().timeIntervalSince1970 * 1000)
    ]
    guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
    var request = URLRequest(url: URL(string: "http://127.0.0.1:7612/ingest/6c1ebb5d-2cad-4d30-8c36-f313e6f114be")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("bd5c3b", forHTTPHeaderField: "X-Debug-Session-Id")
    request.httpBody = body
    URLSession.shared.dataTask(with: request).resume()
    let path = "/Users/nexg/Documents/Viewlift/Frameworks/ViewLift-IOS-PlayerFramework/.cursor/debug-bd5c3b.log"
    guard let line = String(data: body, encoding: .utf8)?.appending("\n").data(using: .utf8) else { return }
    if FileManager.default.fileExists(atPath: path), let handle = FileHandle(forWritingAtPath: path) {
        handle.seekToEndOfFile()
        handle.write(line)
        try? handle.close()
    } else {
        FileManager.default.createFile(atPath: path, contents: line)
    }
    if let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let url = directory.appendingPathComponent("debug-bd5c3b.log")
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: line)
        }
    }
}
// #endregion
