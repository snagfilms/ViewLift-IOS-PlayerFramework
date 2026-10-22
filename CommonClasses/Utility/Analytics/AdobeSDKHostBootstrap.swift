//
//  AdobeSDKHostBootstrap.swift
//  ViewliftPlayerSampleApp
//
//  Host-owned Adobe Mobile Core init for the client duplicate-init scenario.
//  Pair with VLAnalytics.configureAdobeSDKMode(.hostManaged).
//

import Foundation
import UIKit
import AEPCore
import AEPAnalytics
import AEPIdentity
import AEPMedia
import VLAnalyticsLib

/// Host-app Adobe bootstrap used to recreate client-owned Adobe init.
enum AdobeSDKHostBootstrap {

    private static let adobeEnvIdKey = "Adobe_Env_Id"
    private static var didBootstrap = false

    /// Call this from the host app *before* `VLAnalytics.shared.setupAnalytics(...)`.
    /// Host owns Adobe privacy/lifecycle in `.hostManaged` mode.
    static func initializeIfNeeded(completion: (() -> Void)? = nil) {
        guard !didBootstrap else {
            DispatchQueue.main.async { completion?() }
            return
        }
        didBootstrap = true

        guard let appId = resolveAdobeEnvironmentId(), !appId.isEmpty else {
            DispatchQueue.main.async { completion?() }
            return
        }

        let extensions: [NSObject.Type] = [
            Media.self,
            Analytics.self,
            Identity.self
        ]

        MobileCore.registerExtensions(extensions) {
            DispatchQueue.main.async {
                MobileCore.configureWith(appId: appId)
                MobileCore.setPrivacyStatus(.optedIn)

                if UIApplication.shared.applicationState != .background {
                    MobileCore.lifecycleStart(additionalContextData: nil)
                }

                VLAnalytics.shared.markAdobeHostReady()
                completion?()
            }
        }
    }

    private static func resolveAdobeEnvironmentId() -> String? {
        if let siteConfigPath = Bundle.main.path(forResource: "SiteConfig", ofType: "plist"),
           let siteConfig = NSDictionary(contentsOfFile: siteConfigPath) as? [String: Any],
           let envId = siteConfig[adobeEnvIdKey] as? String,
           !envId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return envId
        }

        if let envId = Bundle.main.object(forInfoDictionaryKey: adobeEnvIdKey) as? String,
           !envId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return envId
        }

        return nil
    }
}
