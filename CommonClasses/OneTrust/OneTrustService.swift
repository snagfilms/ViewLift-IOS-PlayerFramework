//
//  OneTrustService.swift
//  ViewliftPlayerSampleApp
//
//  Copyright © 2026 Viewlift. All rights reserved.
//

import Foundation
import UIKit
import AppTrackingTransparency
import VLAnalyticsLib
#if os(tvOS)
import OTPublishersHeadlessSDKtvOS
#else
import OTPublishersHeadlessSDK
#endif

protocol OneTrustServiceDelegate: AnyObject {
    func consentViewDismissed()
}

enum OneTrustStorageKey {
    static let showPopup = "OneShownPopup"
    static let usPrivacy = "IABUSPrivacy_String"
    static let gppSID = "IABGPP_GppSID"
    static let gpp = "IABGPP_HDR_GppString"
    static let featureEnabled = "OnetrustLaunch"
}

enum OneTrustMacro {
    static let usPrivacy = "VIEWLIFT_US_PRIVACY"
    static let gppSID = "VIEWLIFT_GPP_SID"
    static let gpp = "VIEWLIFT_GPP"
}

final class OneTrustService {

    static let shared = OneTrustService()

    weak var delegate: OneTrustServiceDelegate?
    private(set) var isTrackingEnabled = true
    var consentStatus: Bool?

    private var isRequestingTracking = false
    private var trackingCompletions: [() -> Void] = []

    private var configuration: OneTrustDetail? {
        AppDelegate.shared.readVideoListOperation?.videoList?.oneTrust
    }

    var isEnabled: Bool {
        guard let configuration, configuration.enabled else { return false }
        let domainIdentifier = configuration.domainID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let storageLocation = configuration.storageLocation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !domainIdentifier.isEmpty && !storageLocation.isEmpty
    }

    private init() {}

    func prepareForLaunch() {
        // #region agent log
        writeDebugLog(
            hypothesisId: "H1",
            location: "OneTrustService.swift:prepareForLaunch",
            message: "OneTrust launch configuration evaluated",
            data: [
                "isEnabled": isEnabled,
                "domainIDLength": configuration?.domainID?.count ?? 0,
                "storageLocation": configuration?.storageLocation ?? ""
            ]
        )
        // #endregion
        guard isEnabled else { return }
        #if os(tvOS)
        checkForTracking { [weak self] in
            self?.configure()
        }
        #else
        configure()
        #endif
    }

    func configure() {
        guard isEnabled else { return }
        OTPublishersHeadlessSDK.shared.addEventListener(self)
        OTPublishersHeadlessSDK.shared.enableOTSDKLog(.debug)
        checkConsentPermission()
        updateAnalyticsConsent()
    }

    func launchBannerIfNeeded(completion: ((Bool) -> Void)? = nil) {
        // #region agent log
        writeDebugLog(
            hypothesisId: "H2",
            location: "OneTrustService.swift:launchBannerIfNeeded",
            message: "OneTrust banner eligibility evaluated",
            data: [
                "isEnabled": isEnabled,
                "hasShownPopup": UserDefaults.standard.bool(forKey: OneTrustStorageKey.showPopup),
                "trackingStatus": String(describing: ATTrackingManager.trackingAuthorizationStatus),
                "countryCode": currentCountryCode()
            ]
        )
        // #endregion
        guard isEnabled else {
            completion?(false)
            return
        }
        let hasShownOneTrust = UserDefaults.standard.bool(forKey: OneTrustStorageKey.showPopup)
        guard !hasShownOneTrust else {
            completion?(false)
            return
        }

        let sdkParams = OTSdkParams(countryCode: currentCountryCode(), regionCode: nil)
        let hasAuthorizationToken = AppDelegate.shared.authorizationToken != nil
        showBanner(param: hasAuthorizationToken ? sdkParams : nil, completion: completion ?? { _ in })
    }

    func privacyMacros() -> [String: String] {
        guard isEnabled else {
            return [
                OneTrustMacro.usPrivacy: "",
                OneTrustMacro.gppSID: "",
                OneTrustMacro.gpp: ""
            ]
        }
        let defaults = UserDefaults.standard
        return [
            OneTrustMacro.usPrivacy: defaults.string(forKey: OneTrustStorageKey.usPrivacy) ?? "",
            OneTrustMacro.gppSID: defaults.string(forKey: OneTrustStorageKey.gppSID) ?? "",
            OneTrustMacro.gpp: defaults.string(forKey: OneTrustStorageKey.gpp) ?? ""
        ]
    }

    func showBanner(param: OTSdkParams?, completion: @escaping (Bool) -> Void) {
        let status = ATTrackingManager.trackingAuthorizationStatus
        // #region agent log
        let attBranch: String
        if status == .notDetermined {
            attBranch = "notDetermined"
        } else if status == .denied {
            attBranch = "denied"
        } else {
            attBranch = "showOTBanner"
        }
        writeDebugLog(
            hypothesisId: "H3",
            location: "OneTrustService.swift:showBanner",
            message: "ATT branch selected before OneTrust UI",
            data: [
                "trackingStatus": String(describing: status),
                "branch": attBranch,
                "hasSdkParams": param != nil
            ]
        )
        // #endregion
        if status == .notDetermined {
            checkForTracking { [weak self] in
                guard ATTrackingManager.trackingAuthorizationStatus != .denied else {
                    completion(false)
                    return
                }
                self?.showOTBanner(param: param, completion: completion)
            }
        } else if status == .denied {
            completion(false)
        } else {
            showOTBanner(param: param, completion: completion)
        }
    }

    func showPreferenceCenter(param: OTSdkParams?) {
        guard isEnabled else { return }
        #if os(tvOS)
        showPreferenceCenterTV(param: param)
        #else
        showPreferenceCenterIOS(param: param)
        #endif
    }

    func checkConsentPermission() {
        let trackingStatus = ATTrackingManager.trackingAuthorizationStatus
        isTrackingEnabled = trackingStatus == .authorized || trackingStatus == .notDetermined
        guard isEnabled else { return }
        let targetingStatus = OTPublishersHeadlessSDK.shared.getConsentStatus(forCategory: "C0004")
        let socialStatus = OTPublishersHeadlessSDK.shared.getConsentStatus(forCategory: "C0005")
        isTrackingEnabled = targetingStatus > 0 && socialStatus > 0
    }

    private var shouldClearConsentData: Bool {
        guard let userId = UserManager.shared.userIdentity?.userId, !userId.isEmpty else {
            return false
        }
        return OneTrustUserDefaultsHelper.shared.retrieveValue(forKey: userId) == nil
    }

    private func showOTBanner(param: OTSdkParams?, completion: @escaping (Bool) -> Void) {
        startSDK(param: param) { response in
            // #region agent log
            self.writeDebugLog(
                hypothesisId: "H3",
                location: "OneTrustService.swift:showOTBanner",
                message: "OneTrust SDK setup completed",
                data: [
                    "hasError": response.error != nil,
                    "errorDescription": response.error?.localizedDescription ?? "",
                    "errorDomain": (response.error as NSError?)?.domain ?? "",
                    "errorCode": (response.error as NSError?)?.code ?? -1,
                    "hasBannerData": OTPublishersHeadlessSDK.shared.getBannerData() != nil
                ]
            )
            // #endregion
            guard response.error == nil else {
                completion(false)
                return
            }
            let shouldShowBanner = OTPublishersHeadlessSDK.shared.shouldShowBanner()
            // #region agent log
            self.writeDebugLog(
                hypothesisId: "H4",
                location: "OneTrustService.swift:showOTBanner",
                message: "OneTrust banner visibility evaluated",
                data: [
                    "shouldShowBanner": shouldShowBanner,
                    "featureLaunchFlagPresent": UserDefaults.standard.string(forKey: OneTrustStorageKey.featureEnabled) != nil
                ]
            )
            // #endregion
            guard shouldShowBanner else {
                completion(false)
                return
            }
            DispatchQueue.main.async {
                guard let topViewController = AppDelegate.shared.window?.rootViewController else {
                    // #region agent log
                    self.writeDebugLog(
                        hypothesisId: "H6",
                        location: "OneTrustService.swift:showOTBanner",
                        message: "Banner skipped because root view controller missing",
                        data: ["hasWindow": AppDelegate.shared.window != nil]
                    )
                    // #endregion
                    completion(false)
                    return
                }
                if UserDefaults.standard.string(forKey: OneTrustStorageKey.featureEnabled) == nil {
                    UserDefaults.standard.set("true", forKey: OneTrustStorageKey.featureEnabled)
                    OTPublishersHeadlessSDK.shared.setupUI(topViewController, UIType: .banner)
                    OTPublishersHeadlessSDK.shared.showConsentUI(for: .idfa, from: topViewController) {}
                    // #region agent log
                    self.writeDebugLog(
                        hypothesisId: "H5",
                        location: "OneTrustService.swift:showOTBanner",
                        message: "OneTrust banner presentation requested",
                        data: [
                            "hasRootViewController": true,
                            "uiApi": "showConsentUI.idfa",
                            "presenter": String(describing: type(of: topViewController))
                        ]
                    )
                    // #endregion
                } else {
                    // #region agent log
                    self.writeDebugLog(
                        hypothesisId: "H5",
                        location: "OneTrustService.swift:showOTBanner",
                        message: "Banner skipped because OnetrustLaunch already set",
                        data: [
                            "featureLaunchValue": UserDefaults.standard.string(forKey: OneTrustStorageKey.featureEnabled) ?? ""
                        ]
                    )
                    // #endregion
                    completion(false)
                }
            }
        }
    }

    private func startSDK(param: OTSdkParams?, completion: @escaping (OTResponse) -> Void) {
        let storageLocation = configuration?.storageLocation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let domainIdentifier = configuration?.domainID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard isEnabled, !storageLocation.isEmpty, !domainIdentifier.isEmpty else {
            // #region agent log
            writeDebugLog(
                hypothesisId: "H7",
                location: "OneTrustService.swift:startSDK",
                message: "startSDK returned before SDK call",
                data: [
                    "isEnabled": isEnabled,
                    "storageLocationEmpty": storageLocation.isEmpty,
                    "domainIdentifierEmpty": domainIdentifier.isEmpty
                ]
            )
            // #endregion
            return
        }
        OTPublishersHeadlessSDK.shared.startSDK(
            storageLocation: storageLocation,
            domainIdentifier: domainIdentifier,
            languageCode: "en",
            params: param,
            completionHandler: completion
        )
    }

    #if os(iOS)
    private func showPreferenceCenterIOS(param: OTSdkParams?) {
        DispatchQueue.main.async {
            let rootViewController = AppDelegate.shared.window?.rootViewController
            let topViewController = rootViewController?.presentedViewController ?? rootViewController
            if OTPublishersHeadlessSDK.shared.getBannerData() != nil, let topViewController {
                OTPublishersHeadlessSDK.shared.setupUI(topViewController, UIType: .preferenceCenter)
                OTPublishersHeadlessSDK.shared.showPreferenceCenterUI()
                UserDefaults.standard.set(true, forKey: OneTrustStorageKey.showPopup)
            } else if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                self.checkForTracking { [weak self] in
                    self?.startSDK(param: param) { response in
                        guard response.error == nil else { return }
                        DispatchQueue.main.async {
                            let root = AppDelegate.shared.window?.rootViewController
                            guard let top = root?.presentedViewController ?? root else { return }
                            OTPublishersHeadlessSDK.shared.setupUI(top, UIType: .preferenceCenter)
                            OTPublishersHeadlessSDK.shared.showPreferenceCenterUI()
                        }
                    }
                }
            } else {
                self.startSDK(param: param) { response in
                    guard response.error == nil else { return }
                    DispatchQueue.main.async {
                        let root = AppDelegate.shared.window?.rootViewController
                        guard let top = root?.presentedViewController ?? root else { return }
                        OTPublishersHeadlessSDK.shared.setupUI(top, UIType: .preferenceCenter)
                        OTPublishersHeadlessSDK.shared.showPreferenceCenterUI()
                    }
                }
            }
        }
    }
    #endif

    #if os(tvOS)
    private func showPreferenceCenterTV(param: OTSdkParams?) {
        DispatchQueue.main.async {
            self.startSDK(param: param) { response in
                guard response.error == nil else { return }
                DispatchQueue.main.async {
                    guard let topViewController = AppDelegate.shared.window?.rootViewController else { return }
                    OTPublishersHeadlessSDK.shared.setupUI(topViewController, UIType: .preferenceCenter)
                    OTPublishersHeadlessSDK.shared.showPreferenceCenterUI()
                }
            }
        }
    }
    #endif

    private func checkForTracking(completion: (() -> Void)? = nil) {
        let trackingStatus = ATTrackingManager.trackingAuthorizationStatus
        if trackingStatus != .notDetermined {
            completion?()
            return
        }
        if let completion {
            trackingCompletions.append(completion)
        }
        guard !isRequestingTracking else { return }
        isRequestingTracking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isRequestingTracking = false
                    let callbacks = self.trackingCompletions
                    self.trackingCompletions.removeAll()
                    callbacks.forEach { $0() }
                }
            }
        }
    }

    private func currentCountryCode() -> String {
        if #available(iOS 16, tvOS 16, *) {
            return (Locale.current.region?.identifier ?? "US").uppercased()
        }
        return (Locale.current.regionCode ?? "US").uppercased()
    }

    private func updateAnalyticsConsent() {
        guard isEnabled else { return }
        VLAnalytics.shared.setConsent(
            analyticsStorageIsAllowed: isTrackingEnabled,
            adStorageIsAllowed: isTrackingEnabled,
            adUserDataIsAllowed: true
        )
    }

    private func recordConsentForLoggedInUser() {
        guard shouldClearConsentData, let userId = UserManager.shared.userIdentity?.userId else { return }
        OneTrustUserDefaultsHelper.shared.createOrUpdateValue(forKey: userId, shownConsent: true)
    }

    // #region agent log
    private func writeDebugLog(
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any]
    ) {
        var payload: [String: Any] = data
        payload["sessionId"] = "819f31"
        payload["runId"] = "pre-fix"
        payload["hypothesisId"] = hypothesisId
        payload["location"] = location
        payload["message"] = message
        payload["timestamp"] = Int(Date().timeIntervalSince1970 * 1000)
        guard JSONSerialization.isValidJSONObject(payload),
              let encodedPayload = try? JSONSerialization.data(withJSONObject: payload),
              let jsonLine = String(data: encodedPayload, encoding: .utf8) else {
            return
        }
        print("DBG0088BB \(jsonLine)")
        let ingestURLs = [
            "http://192.168.1.68:7613/ingest/6c1ebb5d-2cad-4d30-8c36-f313e6f114be"
        ]
        for urlString in ingestURLs {
            guard let url = URL(string: urlString) else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("819f31", forHTTPHeaderField: "X-Debug-Session-Id")
            request.httpBody = encodedPayload
            URLSession.shared.dataTask(with: request) { _, _, error in
                if let error {
                    print("DBG0088BB ingest failed \(error.localizedDescription)")
                }
            }.resume()
        }
    }
    // #endregion
}

extension OneTrustService: OTEventListener {

    func allSDKViewsDismissed(interactionType: ConsentInteractionType) {
        OTPublishersHeadlessSDK.shared.checkAndLogConsent(for: .idfa)
        UserDefaults.standard.set(true, forKey: OneTrustStorageKey.showPopup)
        recordConsentForLoggedInUser()
        delegate?.consentViewDismissed()
        checkConsentPermission()
        updateAnalyticsConsent()
    }

    func onPreferenceCenterPurposeConsentChanged(purposeId: String, consentStatus: Int8) {
        self.consentStatus = consentStatus == 1
    }
}
