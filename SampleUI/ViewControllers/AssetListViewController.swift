//
//  AssetListViewController.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 03/07/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import UIKit
import VLPlayerLib
#if os(iOS)
import VLAuthenticationFramework
#else
import VLAuthenticationFramework_tvOS
#endif
import Kingfisher
import AppTrackingTransparency
import VLAnalyticsLib


class AssetListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView()
    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)
    private let providerImageView = UIImageView()
    private let titleLabel = UILabel()
    #if os(iOS)
    private let analyticsTrackingSwitch = UISwitch()
    private let analyticsTrackingStatusLabel = UILabel()
    #elseif os(tvOS)
    private let analyticsTrackingButton = UIButton(type: .system)
    #endif
    private let analyticsTrackingPreferenceKey = "analyticsTrackingIsAllowed"
    
    // MARK: - Data
    
    var videoList: VideoList!
    var entitlementData: VLPlayer.EntitlementData?
    private var assetModels: [AssetModel] = []
    var configurableHeaderView: ConfigurableHeaderView?

    #if os(tvOS)
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [analyticsTrackingButton, tableView]
    }
    #endif
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        #if os(iOS)
        setupDarkModeSupport()
        #else
        view.backgroundColor = .tvOSAdaptiveBackground
        #endif
       
        
        guard videoList != nil else {
            showAlert(title: "Error", message: "Please provide valid video list data. Replace configs.json content.")
            return
        }
        
        videoList.nextVideoList?.removeAll()
        setupAnalyticsTrackingToggle()
        setupHeader()
        setupTableView()
        assetModels = loadAssetModelsFromFile() ?? []
    }
    
    #if os(iOS)
    // MARK: - Dark Mode Support
    
    private func setupDarkModeSupport() {
        // Ensure the view adapts to dark mode
        view.backgroundColor = .systemBackground
        
        // Allow system to control appearance
        overrideUserInterfaceStyle = .unspecified
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Update UI when dark mode changes
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColorsForCurrentTraitCollection()
        }
    }
    
    private func updateColorsForCurrentTraitCollection() {
        // Refresh UI elements for current appearance
        view.backgroundColor = .systemBackground
        headerView.backgroundColor = .systemBackground
        tableView.backgroundColor = .systemBackground
        tableView.separatorColor = .separator
        titleLabel.textColor = .label
        
        // Reload table view to update cell colors
        tableView.reloadData()
    }
    #endif

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

#if os(iOS)
        navigationController?.setNavigationBarHidden(false, animated: animated)
#endif
        updateAnalyticsTrackingToggleAppearance()
        
        // Default: hide both controls
        logoutButton.isHidden = true
        providerImageView.isHidden = true
        
#if os(tvOS)
        if UserManager.shared.userIdentity != nil {
            logoutButton.isHidden = false
            providerImageView.isHidden = false
        }
#endif
        
        guard let videoList = AppDelegate.shared.readVideoListOperation?.videoList else { return }
        let xApiKey = videoList.xApiKey
        let siteId = videoList.authKeys.siteId
        let apiBaseEndpoint = videoList.authKeys.apiBaseEndpoint
        
        showAlertIfConfigInvalid(
            apiBaseEndpoint: apiBaseEndpoint,
            authorizationToken: AppDelegate.shared.authorizationToken,
            siteId: siteId,
            xApiKey: xApiKey,
            alertMessage: "Detected invalid configuration! Please update your settings."
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    // your status handling here
                }
            }
    }
    
    func fetchUserDetails() {
        Task {
            do {
                let userIdentity = try await VLAuthentication.sharedInstance.getUserIdentity()
                
                if let tvImageurl = userIdentity.tveMetadata?.imageUrl {
                    self.providerImageView.isHidden = false
                    self.providerImageView.backgroundColor = .black
                    
                    if let url = URL(string: tvImageurl) {
                        self.providerImageView.kf.setImage(with: url)
                    }
                }
            } catch {
                debugPrint(error)
                self.providerImageView.isHidden = true
            }
        }
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let headerView = configurableHeaderView else { return }
        let height = headerView.heightFittingWidth(tableView.bounds.width)
        
        if tableView.tableHeaderView?.frame.height != height {
            headerView.frame = CGRect(x: 0,
                                      y: 0,
                                      width: tableView.bounds.width,
                                      height: height)
            tableView.tableHeaderView = headerView
        }
    }
    
    // MARK: - Header Setup

    private func setupAnalyticsTrackingToggle() {
        let isAllowed = UserDefaults.standard.object(forKey: analyticsTrackingPreferenceKey) as? Bool ?? true

        #if os(iOS)
        analyticsTrackingSwitch.isOn = isAllowed
        analyticsTrackingSwitch.accessibilityIdentifier = "analyticsTrackingToggle"
        analyticsTrackingSwitch.addTarget(self, action: #selector(analyticsTrackingToggled), for: .valueChanged)

        analyticsTrackingStatusLabel.font = .preferredFont(forTextStyle: .caption2)
        analyticsTrackingStatusLabel.adjustsFontForContentSizeCategory = true
        analyticsTrackingStatusLabel.textAlignment = .right

        let analyticsControl = UIStackView(arrangedSubviews: [analyticsTrackingStatusLabel, analyticsTrackingSwitch])
        analyticsControl.axis = .horizontal
        analyticsControl.alignment = .center
        analyticsControl.spacing = 4
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: analyticsControl)
        #else
        analyticsTrackingButton.accessibilityIdentifier = "analyticsTrackingToggle"
        analyticsTrackingButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        analyticsTrackingButton.addTarget(self, action: #selector(analyticsTrackingToggled), for: .primaryActionTriggered)
        #endif

        applyAnalyticsTracking(isAllowed: isAllowed)
    }

    @objc private func analyticsTrackingToggled() {
        #if os(iOS)
        applyAnalyticsTracking(isAllowed: analyticsTrackingSwitch.isOn)
        #else
        let isAllowed = UserDefaults.standard.object(forKey: analyticsTrackingPreferenceKey) as? Bool ?? true
        applyAnalyticsTracking(isAllowed: !isAllowed)
        #endif
    }

    private func applyAnalyticsTracking(isAllowed: Bool) {
        UserDefaults.standard.set(isAllowed, forKey: analyticsTrackingPreferenceKey)
        VLAnalytics.shared.manageAnalyticsTracking(isAllowed: isAllowed)
        debugPrint("Analytics tracking is now \(isAllowed ? "enabled" : "disabled")")
        updateAnalyticsTrackingToggleAppearance()
    }

    private func updateAnalyticsTrackingToggleAppearance() {
        let isAllowed = UserDefaults.standard.object(forKey: analyticsTrackingPreferenceKey) as? Bool ?? true
        #if os(iOS)
        analyticsTrackingSwitch.isOn = isAllowed
        analyticsTrackingStatusLabel.text = isAllowed ? "Analytics On" : "Analytics Off"
        analyticsTrackingSwitch.accessibilityLabel = analyticsTrackingStatusLabel.text
        analyticsTrackingSwitch.accessibilityValue = isAllowed ? "Enabled" : "Disabled"
        #else
        let title = isAllowed ? "Analytics On" : "Analytics Off"
        analyticsTrackingButton.setTitle(title, for: .normal)
        analyticsTrackingButton.accessibilityLabel = title
        analyticsTrackingButton.accessibilityValue = isAllowed ? "Enabled" : "Disabled"
        analyticsTrackingButton.accessibilityHint = "Press to change analytics tracking"
        #endif
    }

    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        #if os(iOS)
        headerView.backgroundColor = .systemBackground
        #else
        headerView.backgroundColor = .tvOSAdaptiveBackground
        #endif
        view.addSubview(headerView)
        
        // --- Back Button (Left) ---
        backButton.setTitle("← Back", for: .normal)
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self,
                             action: #selector(backTapped),
                             for: .touchUpInside)
        headerView.addSubview(backButton)
        
        var titleLabelFontSize: CGFloat = 18
#if os(tvOS)
        backButton.isHidden = true
        titleLabelFontSize = 36
#endif
        
        // --- Logout Button (Right) ---
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.setTitleColor(.systemRed, for: .normal)
        logoutButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.addTarget(self,
                               action: #selector(logoutTapped),
                               for: .primaryActionTriggered)
        headerView.addSubview(logoutButton)

#if os(tvOS)
        analyticsTrackingButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(analyticsTrackingButton)
#endif
        
        // --- Status ImageView (left of Logout) ---
        providerImageView.translatesAutoresizingMaskIntoConstraints = false
        providerImageView.contentMode = .scaleAspectFit
        headerView.addSubview(providerImageView)
        
        // default hidden; will toggle with logoutButton
        logoutButton.isHidden = true
        providerImageView.isHidden = true
        
#if os(tvOS)
        if UserManager.shared.userIdentity != nil {
            logoutButton.isHidden = false
            
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                self.fetchUserDetails()
            }
        }
#endif
        
        // --- Title Label (Center) ---
        titleLabel.text = "Assets"
        titleLabel.font = .boldSystemFont(ofSize: titleLabelFontSize)
        titleLabel.textAlignment = .center
        // `.label` adapts to the appearance (dark text in Light mode, light text in Dark)
        // and is available on both iOS and tvOS.
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        // --- Constraints ---
        var constraints: [NSLayoutConstraint] = [
            // Header view
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50),

            // Back button
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Logout button (right)
            logoutButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            logoutButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Title label (center)
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ]

        // Status image (immediately left of Logout / Analytics button)
        #if os(tvOS)
        constraints.append(providerImageView.trailingAnchor.constraint(equalTo: analyticsTrackingButton.leadingAnchor, constant: -8))
        #else
        constraints.append(providerImageView.trailingAnchor.constraint(equalTo: logoutButton.leadingAnchor, constant: -8))
        #endif

        constraints.append(contentsOf: [
            providerImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            providerImageView.widthAnchor.constraint(equalToConstant: 200),
            providerImageView.heightAnchor.constraint(equalToConstant: 112)
        ])

        NSLayoutConstraint.activate(constraints)

#if os(tvOS)
        NSLayoutConstraint.activate([
            analyticsTrackingButton.trailingAnchor.constraint(equalTo: logoutButton.leadingAnchor, constant: -16),
            analyticsTrackingButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
#endif
    }
    
    // MARK: - Table View Setup (unchanged)
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        #if os(iOS)
        tableView.backgroundColor = .systemBackground
        tableView.separatorColor = .separator
        #else
        tableView.backgroundColor = .tvOSAdaptiveBackground
        #endif
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.register(AssetTableViewCell.self,
                           forCellReuseIdentifier: AssetTableViewCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    // MARK: - Button Actions
    
    @objc private func backTapped() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func logoutTapped() {
        let mvpdProvider = UserManager.shared.userIdentity?.mvpdProvider
        
        VLAuthentication.sharedInstance.logout(
            client: .tvProvider(provider: .adobe, tveInitializationConfig: nil),
            mvpdId: mvpdProvider
        ) { [weak self] logoutSuccessful in
            if logoutSuccessful {
                Task { [weak self] in
                    AnalyticsHelperV2.shared.triggerSignoutAnalytics()
                    
                    self?.logoutButton.isHidden = true
                    self?.providerImageView.isHidden = true  // ← sync state
                    await AppDelegate.shared.logoutUser()
                }
            }
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
            launchVideoPlayer(url: url, isExternal: asset.isExternal ?? false, streamConfig: VLPlayer.StreamConfig(isLive: asset.isLive, isDVR: asset.isDVR), channelId: asset.channelId ?? [])
        case .videoId(let id):
            print("Play using videoId: \(id)")
            launchVideoPlayer(
                videoId: id,
                isExternal: asset.isExternal ?? false,
                channelId: asset.channelId ?? [])
        }
    }
    
    private func launchVideoPlayer(videoId: String? = nil, url: String? = nil, isExternal: Bool = false, streamConfig: VLPlayer.StreamConfig? = nil, channelId: [String]) {
        guard (videoId != nil && !videoId!.isEmpty) || (url != nil && !url!.isEmpty) else {return}
            
        var drmConfig: VLPlayer.DRMConfig?
        if let videoId = videoId, !videoId.isEmpty {
            videoList.videoId = videoId
            videoList.channelId = channelId
            
            if isExternal{
                getEntitlementData(videoId: videoId) { [weak self] result in
                    switch result {
                    case .success(let data):
                        self?.entitlementData = data
                        DispatchQueue.main.async {
                            self?.loadVideoPlayer(videoId: videoId, channelId: channelId)
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            
                            self?.showAlert(title: "Error", message: (error.errorCode ?? "") + " " + (error.errorMessage ?? ""))
                        }
                    }
                    
                }
            }else{
                self.loadVideoPlayer(videoId: videoId, channelId: channelId)
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
            
            self.loadVideoPlayer(
                url: url,
                drmConfig: drmConfig,
                streamConfig: streamConfig,
                channelId: channelId
            )
            
            
        }
        debugPrint("contentID: \(videoId ?? "nil")")
        
    }
    
    func showAlert(title: String = "Alert!", message: String = "Description") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func loadVideoPlayer(videoId: String? = nil, url: String? = nil, drmConfig: VLPlayer.DRMConfig? = nil, streamConfig: VLPlayer.StreamConfig? = nil, channelId: [String]) {
        let showCustomControls = configurableHeaderView?.getConfigurableItemSelection(type: .showCustomControls) ?? false
        let autoplayEnabled = configurableHeaderView?.getConfigurableItemSelection(type: .autoPlay) ?? true
        let loopEnabled = configurableHeaderView?.getConfigurableItemSelection(type: .loopPlay) ?? false
        let hideControls = configurableHeaderView?.getConfigurableItemSelection(type: .hideControls) ?? false
        let muteEnabled = configurableHeaderView?.getConfigurableItemSelection(type: .mute) ?? false
#if os(iOS)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let videoPlaybackController = storyboard.instantiateViewController(withIdentifier: "PlayerViewController_iOS") as! PlayerViewController_iOS
        videoPlaybackController.streamUrl = url
        videoPlaybackController.entitlementData = self.entitlementData
        videoPlaybackController.streamConfig = streamConfig
        videoPlaybackController.drmConfig = drmConfig
        videoPlaybackController.channelId = channelId
        //        videoPlaybackController.view.frame = self.view.bounds
        videoPlaybackController.prepareView(withPlayerUIOption: videoId == nil ? .playStreamURL : .defaultControl, videoList: videoList)
        videoPlaybackController.enableCustomPlayerUI = showCustomControls
        videoPlaybackController.autoplayEnabled = autoplayEnabled
        videoPlaybackController.loopEnabled = loopEnabled
        videoPlaybackController.hideControls = hideControls
        videoPlaybackController.muteEnabled = muteEnabled
        // videoPlaybackController.modalPresentationStyle = .fullScreen
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.pushViewController(videoPlaybackController, animated: true)
#else
        let vc = PlayerViewController_tvOS()
        vc.playerOptionSelected = videoId == nil ? .playStreamURL : .defaultControl
        vc.enableCustomPlayerUI = showCustomControls
        vc.streamUrl = url
        vc.videoId = videoId
        vc.entitlementData = self.entitlementData
        vc.channelId = channelId
        vc.streamConfig = streamConfig
        vc.drmConfig = drmConfig
        vc.videoList = videoList
        vc.autoplayEnabled = autoplayEnabled
        vc.loopEnabled = loopEnabled
        vc.hideControls = hideControls
        vc.muteEnabled = muteEnabled
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


extension AssetListViewController{
    
    func getEntitlementData(
        videoId: String,
        completion: @escaping (Result<VLPlayer.EntitlementData, VLPlayerLib.VLError>) -> Void
    ) {
        fetchContentDetails(videoId: videoId) { (playerObject, isSuccess, vlError, playerResponse, contentResponse) in
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
    
    func fetchContentDetailsLocal(apiResponse: @escaping (_ playerObject: VLPlayerLib.PlayerObject?, _ isSuccess: Bool, _ vlError: VLPlayerLib.VLError?, _ playerResponse: VLPlayerLib.VLPlayerResponse?, _ contentResponse: Dictionary<String, AnyObject>?) -> Void
    ) {
        
        guard let fallbackURL = Bundle.main.url(forResource: "entitlement", withExtension: "json"),
              let localData = try? Data(contentsOf: fallbackURL) else {
            let error = VLPlayerLib.VLError()
            error.errorCode = ""
            error.errorMessage = ""
            error.vl_errorCode = ""
            error.isPlayable = false
            error.isSuccess = false
            apiResponse(nil, false, error, nil, nil)
            return
        }
        parseEntitlementData(from: localData, apiResponse: apiResponse)
        
    }
}

#if os(tvOS)
extension UIColor {
    static var tvOSAdaptiveBackground: UIColor {
        UIColor { traits in traits.userInterfaceStyle == .dark ? .black : .white }
    }
}
#endif

