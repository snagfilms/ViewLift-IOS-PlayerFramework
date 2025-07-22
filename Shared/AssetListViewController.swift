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
    var entitlementData: VLPlayerLib.EntitlementData?
    private var assetModels: [AssetModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        videoList.nextVideoList?.removeAll()
        setupHeader()
        setupTableView()
        assetModels = loadAssetModelsFromFile() ?? []
        tableView.reloadData()
    }
    
    func getEntitlementData(
        source: ResponseSource,
        completion: @escaping (Result<VLPlayerLib.EntitlementData, VLPlayerLib.VLError>) -> Void
    ) {
        fetchContentDetails(source: source) { (playerObject, isSuccess, vlError, playerResponse, contentResponse) in
            if isSuccess, let playerObject = playerObject {
                let entitlementData = VLPlayerLib.EntitlementData(
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
            launchVideoPlayer(url: url, isExternal: asset.isExternal ?? false)
        case .videoId(let id):
            print("Play using videoId: \(id)")
            launchVideoPlayer(videoId: id, isExternal: asset.isExternal ?? false, responseType: asset.responseType ?? "local")
        }
    }
    
    private func launchVideoPlayer(videoId: String? = nil, url: String? = nil, isExternal: Bool = false, responseType: String = "local") {
        guard (videoId != nil && !videoId!.isEmpty) || (url != nil && !url!.isEmpty) else {return}
            
        var drmConfig: VLPlayerLib.DRMConfig?
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
                drmConfig = VLPlayerLib.DRMConfig(
                    licenseUrl: licenseUrl,
                    certificateUrl: certificateUrl,
                    licenseToken: licenseToken,
                    completeSkd: completeskd
                )
            }
            self.loadVideoPlayer(url: url, drmConfig: drmConfig)
            
            
        }
        debugPrint("contentID: \(videoId ?? "nil")")

    }
    
    func showAlert(title: String = "Alert!", message: String = "Description") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func loadVideoPlayer(videoId: String? = nil, url: String? = nil, drmConfig: VLPlayerLib.DRMConfig? = nil) {
        #if os(iOS)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let videoPlaybackController = storyboard.instantiateViewController(withIdentifier: "VideoPlaybackController") as! VideoPlaybackController
        videoPlaybackController.streamUrl = url
        videoPlaybackController.entitlementData = self.entitlementData
        videoPlaybackController.drmConfig = drmConfig
        videoPlaybackController.view.frame = self.view.bounds
        videoPlaybackController.prepareView(withPlayerUIOption: videoId == nil ? .playStreamURL : .defaultControl, videoList: videoList)
        videoPlaybackController.modalPresentationStyle = .fullScreen
        self.present(videoPlaybackController, animated: true, completion: nil)
        #else
        let vc = PlayerViewController()
        vc.playerOptionSelected = videoId == nil ? .playStreamURL : .defaultControl
        vc.streamUrl = url
        vc.videoId = videoId
        vc.entitlementData = self.entitlementData
        vc.drmConfig = drmConfig
        vc.videoList = videoList
        self.present(vc, animated: true)
        #endif
    }
}

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
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        leftIndexLabel.textColor = .systemBlue
        leftIndexLabel.textAlignment = .center
        leftIndexLabel.setContentHuggingPriority(.required, for: .horizontal)
        leftIndexLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        leftIndexLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.numberOfLines = 0
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textColor = .darkGray
        titleLabel.textColor = .black
       #if os(tvOS)
       leftIndexLabel.font = UIFont.boldSystemFont(ofSize: 32)
       titleLabel.font = UIFont.boldSystemFont(ofSize: 32)
       subtitleLabel.font = UIFont.systemFont(ofSize: 28)
       infoButton.isHidden = true
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

        separatorView.backgroundColor = .black.withAlphaComponent(0.4)
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
            detectDuplicates(assets: assets)
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

struct AssetModel {
    let title: String
    let subtitle: String?
    let playbackType: PlaybackType
    let isExternal: Bool?
    let staticContentId: String?
    let responseType: String?
}

extension AssetModel: Codable {
    enum CodingKeys: String, CodingKey {
        case title, subtitle, videoId, url, isExternal, staticContentId, responseType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        isExternal = try container.decodeIfPresent(Bool.self, forKey: .isExternal)
        staticContentId = try container.decodeIfPresent(String.self, forKey: .staticContentId)
        responseType = try container.decodeIfPresent(String.self, forKey: .responseType)
        let url = try container.decodeIfPresent(String.self, forKey: .url)
        let videoId = try container.decodeIfPresent(String.self, forKey: .videoId)

        if let url = url {
            playbackType = .url(url)
        } else if let videoId = videoId {
            playbackType = .videoId(videoId)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .url, in: container, debugDescription: "Expected either 'url' or 'videoId' to be present.")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)

        switch playbackType {
        case .url(let url):
            try container.encode(url, forKey: .url)
        case .videoId(let videoId):
            try container.encode(videoId, forKey: .videoId)
        }
    }
}

extension AssetListViewController: AssetTableViewCellDelegate {
    func assetCellDidTapInfo(_ cell: AssetTableViewCell, asset: AssetModel) {
        let infoVC = AssetInfoViewController(asset: asset)
        present(infoVC, animated: true)
    }

}


class AssetInfoViewController: UIViewController {
    private let asset: AssetModel

    init(asset: AssetModel) {
        self.asset = asset
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
    }

    private func setupUI() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        closeButton.tintColor = .label
        closeButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = "Title: \(asset.title)"
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Subtitle: \(asset.subtitle ?? "N/A")"
        subtitleLabel.numberOfLines = 0

        let playbackLabel = UILabel()
        playbackLabel.text = {
            switch asset.playbackType {
            case .url(let value): return "Playback: URL - \(value)"
            case .videoId(let value): return "Playback: Video ID - \(value)"
            }
        }()
        playbackLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [closeButton, titleLabel, subtitleLabel, playbackLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .leading

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

}
extension AssetModel {
    var contentIdentifier: String? {
        switch playbackType {
        case .url(let url):
            return url.isEmpty ? nil : url
        case .videoId(let id):
            return id.isEmpty ? nil : id
        }
    }
}
