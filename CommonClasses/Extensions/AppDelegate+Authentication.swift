//
//  AppDelegate+Authentication.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 04/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//
import UIKit

extension AppDelegate {
    // Shared instance of AppDelegate for easy access
    static var shared: AppDelegate {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Could not cast UIApplication delegate as AppDelegate")
        }
        return delegate
    }
}
