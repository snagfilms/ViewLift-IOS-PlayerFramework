//
//  AssetListViewController.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 03/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import UIKit
import VLPlayerLib

class AssetListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    var videoList:VideoList!
    var entitlementData: VLPlayer.EntitlementData?
    private var assetModels: [AssetModel] = []
    var configurableHeaderView: ConfigurableHeaderView?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        if videoList == nil {
            showAlert(title: "Error", message: "Please provide valid video list data. Replace VideoList.json content")
            return
        }
        videoList.nextVideoList?.removeAll()
        setupHeader()
        setupTableView()
        assetModels = loadAssetModelsFromFile() ?? []
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let headerView = self.configurableHeaderView else { return }

        let height = headerView.heightFittingWidth(tableView.bounds.width)
        if tableView.tableHeaderView?.frame.height != height {
            headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: height)
            tableView.tableHeaderView = headerView
        }
    }
    
    private func setupTableHeaderView() {
        let options: [ConfigurableItemType] = [.guestUser, .showCustomControls, .hideControls, .autoPlay, .loopPlay, .mute]
        var items: [ConfigurableItem] = []
        for option in options {
            items.append(ConfigurableItem(type: option, isChecked: option == .autoPlay))
        }

        let headerView = ConfigurableHeaderView(items: items)

        headerView.onHeightChanged = { [weak self, weak headerView] in
            guard let self = self, let headerView = headerView else { return }
            let height = headerView.heightFittingWidth(self.tableView.bounds.width)
            headerView.frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: height)
            self.tableView.tableHeaderView = headerView
        }

        let height = headerView.heightFittingWidth(tableView.bounds.width)
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: height)
        tableView.tableHeaderView = headerView
        configurableHeaderView = headerView
    }

    
    func getEntitlementData(
        source: ResponseSource,
        completion: @escaping (Result<VLPlayer.EntitlementData, VLPlayerLib.VLError>) -> Void
    ) {
        fetchContentDetails(source: source) { (playerObject, isSuccess, vlError, playerResponse, contentResponse) in
            if isSuccess, let playerObject = playerObject {
                let entitlementData = VLPlayer.EntitlementData(
                    playerObject: playerObject,
                    isSuccess: true,
                    error: vlError,
                    playerResponse: playerResponse,
                    contentResponse: contentResponse
                )
                completion(.success(entitlementData))
            } else {
                completion(.failure(vlError ?? VLPlayerLib.VLError()))
            }
        }
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        headerView.backgroundColor = .white
        backButton.setTitle("← Back", for: .normal)
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        headerView.addSubview(backButton)
        var titleLabelFontSize: CGFloat = 18
        #if os(tvOS)
        backButton.isHidden = true
        titleLabelFontSize = 36
        #endif
        titleLabel.text = "Assets"
        titleLabel.font = .boldSystemFont(ofSize: titleLabelFontSize)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        let topMargin: CGFloat = 20
        tableView.backgroundColor = .clear
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: topMargin),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.register(AssetTableViewCell.self, forCellReuseIdentifier: AssetTableViewCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Back Button

    @objc private func backTapped() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assetModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let asset = assetModels[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: AssetTableViewCell.reuseIdentifier, for: indexPath) as! AssetTableViewCell
        cell.configure(with: asset, index: indexPath.row)
            cell.delegate = self
            return cell
        }



    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let errorMessage = videoList.checkForConfigurationErrorMessage() {
            self.showAlert(message: errorMessage)
            return
        }
        self.entitlementData = nil // Reset entitlement data on new selection
        let asset = assetModels[indexPath.row]
        checkForPlayBack(asset: asset, isExternal: asset.isExternal ?? false)
    }
    
    private func checkForPlayBack(asset: AssetModel, isExternal: Bool) {
        switch asset.playbackType {
        case .url(let url):
            print("Play using URL: \(url)")
            launchVideoPlayer(url: url, isExternal: asset.isExternal ?? false, streamConfig: VLPlayer.StreamConfig(isLive: asset.isLive, isDVR: asset.isDVR, isDRM: nil))
        case .videoId(let id):
            print("Play using videoId: \(id)")
            launchVideoPlayer(videoId: id, isExternal: asset.isExternal ?? false, responseType: asset.responseType ?? "local")
        }
    }
    
    private func launchVideoPlayer(videoId: String? = nil, url: String? = nil, isExternal: Bool = false, responseType: String = "local", streamConfig: VLPlayer.StreamConfig? = nil) {
        guard (videoId != nil && !videoId!.isEmpty) || (url != nil && !url!.isEmpty) else {return}
            
        var drmConfig: VLPlayer.DRMConfig?
        if let videoId = videoId, !videoId.isEmpty {
            videoList.videoId = videoId
            if isExternal{
                getEntitlementData(source: responseType == "local" ? .local : .server(videoId: videoId)) { [weak self] result in
                    switch result {
                    case .success(let data):
                        self?.entitlementData = data
                        DispatchQueue.main.async {
                            self?.loadVideoPlayer(videoId: videoId)
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            
                            self?.showAlert(title: "Error", message: (error.errorCode ?? "") + " " + (error.errorMessage ?? ""))
                        }
                    }
                    
                }
            }else{
                self.loadVideoPlayer(videoId: videoId)
            }
        }else{
            if isExternal {
                guard let licenseUrl = videoList.drmConfig?.licenseUrl,
                      let certificateUrl = videoList.drmConfig?.certificateUrl,
                      let licenseToken = videoList.drmConfig?.licenseToken,
                      let completeskd = videoList.drmConfig?.completeskd,
                      !licenseUrl.contains("xxxxx"),
                      !certificateUrl.contains("xxxxx"),
                      !licenseToken.contains("xxxxx"),
                      !completeskd.contains("xxxxx")
                else {
                    showAlert(title: "Error", message: "DRM configuration is missing or contains invalid values.")
                    return
                }
                drmConfig = VLPlayer.DRMConfig(
                    licenseUrl: licenseUrl,
                    certificateUrl: certificateUrl,
                    licenseToken: licenseToken,
                    completeSkd: completeskd
                )
            }
            self.loadVideoPlayer(url: url, drmConfig: drmConfig, streamConfig: streamConfig)
            
            
        }
        debugPrint("contentID: \(videoId ?? "nil")")

    }
    
    func showAlert(title: String = "Alert!", message: String = "Description") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func loadVideoPlayer(videoId: String? = nil, url: String? = nil, drmConfig: VLPlayer.DRMConfig? = nil, streamConfig: VLPlayer.StreamConfig? = nil) {
        let showCustomControls = configurableHeaderView?.getConfigurableItemSelection(type: .showCustomControls) ?? false
        let autoplayEnabled = configurableHeaderView?.getConfigurableItemSelection(type: .autoPlay) ?? true
        let loopEnabled = configurableHeaderView?.getConfigurableItemSelection(type: .loopPlay) ?? false
        let hideControls = configurableHeaderView?.getConfigurableItemSelection(type: .hideControls) ?? false
        let muteEnabled = configurableHeaderView?.getConfigurableItemSelection(type: .mute) ?? false
        let isGuestUser = configurableHeaderView?.getConfigurableItemSelection(type: .guestUser) ?? false
        #if os(iOS)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let videoPlaybackController = storyboard.instantiateViewController(withIdentifier: "VideoPlaybackController") as! VideoPlaybackController
        videoPlaybackController.streamUrl = url
        videoPlaybackController.entitlementData = self.entitlementData
        videoPlaybackController.streamConfig = streamConfig
        videoPlaybackController.drmConfig = drmConfig
        videoPlaybackController.view.frame = self.view.bounds
        videoPlaybackController.prepareView(withPlayerUIOption: videoId == nil ? .playStreamURL : .defaultControl, videoList: videoList)
        videoPlaybackController.enableCustomPlayerUI = showCustomControls
        videoPlaybackController.autoplayEnabled = autoplayEnabled
        videoPlaybackController.loopEnabled = loopEnabled
        videoPlaybackController.hideControls = hideControls
        videoPlaybackController.muteEnabled = muteEnabled
        videoPlaybackController.isGuestUser = isGuestUser
        videoPlaybackController.modalPresentationStyle = .fullScreen
        self.present(videoPlaybackController, animated: true, completion: nil)
        #else
        let vc = PlayerViewController()
        vc.playerOptionSelected = videoId == nil ? .playStreamURL : .defaultControl
        vc.enableCustomPlayerUI = showCustomControls
        vc.streamUrl = url
        vc.videoId = videoId
        vc.entitlementData = self.entitlementData
        vc.streamConfig = streamConfig
        vc.drmConfig = drmConfig
        vc.videoList = videoList
        vc.autoplayEnabled = autoplayEnabled
        vc.loopEnabled = loopEnabled
        vc.hideControls = hideControls
        vc.muteEnabled = muteEnabled
        vc.isGuestUser = isGuestUser
        //self.present(vc, animated: true)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(vc, animated: true)
        #endif
    }
}

extension AssetListViewController{
    func loadAssetModelsFromFile() -> [AssetModel]? {
        guard let url = Bundle.main.url(forResource: "assets-provider", withExtension: "json") else {
            print("❌ File not found")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let assets = try decoder.decode([AssetModel].self, from: data)
            //detectDuplicates(assets: assets)
            return assets
        } catch {
            print("❌ Decoding error: \(error)")
            return nil
        }
    }
    
    private func detectDuplicates(assets: [AssetModel]){

        let duplicates = findDuplicateAssets(from: assets)

        if duplicates.isEmpty {
            print("✅ No duplicates")
        } else {
            for (key, group) in duplicates {
                print("❗️Duplicate for key: \(key)")
                for item in group {
                    print(" - \(item.title)")
                }
            }
        }

    }
    func findDuplicateAssets(from assets: [AssetModel]) -> [String: [AssetModel]] {
        var seen: [String: [AssetModel]] = [:]

        for asset in assets {
            guard let key = asset.contentIdentifier else { continue }
            seen[key, default: []].append(asset)
        }

        return seen.filter { $1.count > 1 }
    }

    
}

enum PlaybackType {
    case url(String)
    case videoId(String)
}

extension PlaybackType: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum PlaybackTypeIdentifier: String, Codable {
        case url
        case videoId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PlaybackTypeIdentifier.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)

        switch type {
        case .url:
            self = .url(value)
        case .videoId:
            self = .videoId(value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .url(let value):
            try container.encode(PlaybackTypeIdentifier.url, forKey: .type)
            try container.encode(value, forKey: .value)
        case .videoId(let value):
            try container.encode(PlaybackTypeIdentifier.videoId, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

extension AssetListViewController: AssetTableViewCellDelegate {
    func assetCellDidTapInfo(_ cell: AssetTableViewCell, asset: AssetModel) {
        let infoVC = AssetInfoViewController(asset: asset)
        present(infoVC, animated: true)
    }

}


extension UIView {
    
    func heightFittingWidth(_ width: CGFloat) -> CGFloat {
        let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        return systemLayoutSizeFitting(targetSize,
                                       withHorizontalFittingPriority: .required,
                                       verticalFittingPriority: .fittingSizeLevel).height
    }
}


