//
//  UIViewController+extension.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 05/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import UIKit
extension UIViewController {
    /// Checks if a string contains substring "xxxxx" five or more times.
    /// If yes, presents an alert with the specified message.
    /// - Parameters:
    ///   - apiBaseEndpoint: String to check
    ///   - graphQLEndpoint: String to check
    ///   - authorizationToken: Optional string (skipped in check since optional)
    ///   - siteId: String to check
    ///   - xApiKey: String to check
    ///   - alertMessage: The message to show in alert if condition met
    func showAlertIfConfigInvalid(apiBaseEndpoint: String,
                                  authorizationToken: String?,
                                  siteId: String,
                                  xApiKey: String,
                                  alertMessage: String) {
        func containsFiveTimesX(_ value: String) -> Bool {
            value == "xxxxx"
        }

        // Check each relevant property for the repeated "xxxxx"
        let isInvalid = containsFiveTimesX(apiBaseEndpoint) ||
                        containsFiveTimesX(siteId) ||
                        containsFiveTimesX(xApiKey)

        // Show alert if invalid config found
        guard isInvalid else { return }

        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Configuration Warning",
                                          message: alertMessage,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
