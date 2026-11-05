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
            guard response.error == nil else {
                completion(false)
                return
            }
            let shouldShowBanner = OTPublishersHeadlessSDK.shared.shouldShowBanner()
            guard shouldShowBanner else {
                completion(false)
                return
            }
            DispatchQueue.main.async {
                guard let topViewController = AppDelegate.shared.window?.rootViewController else {
                    completion(false)
                    return
                }
                if UserDefaults.standard.string(forKey: OneTrustStorageKey.featureEnabled) == nil {
                    UserDefaults.standard.set("true", forKey: OneTrustStorageKey.featureEnabled)
                    OTPublishersHeadlessSDK.shared.setupUI(topViewController, UIType: .banner)
                    OTPublishersHeadlessSDK.shared.showConsentUI(for: .idfa, from: topViewController) {}
                } else {
                    completion(false)
                }
            }
        }
    }

    private func startSDK(param: OTSdkParams?, completion: @escaping (OTResponse) -> Void) {
        let storageLocation = configuration?.storageLocation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let domainIdentifier = configuration?.domainID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard isEnabled, !storageLocation.isEmpty, !domainIdentifier.isEmpty else {
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
