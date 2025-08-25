//
//  UIWindow+Extension.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 21/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

extension UIWindow {
    static var isLandscape: Bool{
        return UIApplication.shared.statusBarOrientation.isLandscape
    }
}
