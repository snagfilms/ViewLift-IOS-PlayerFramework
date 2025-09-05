//
//  String+Extension.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 03/09/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import Foundation

extension String {
    /// Returns a new string by repeating the current string `times` number of times.
    func multiplied(by times: Int) -> String {
        guard times > 0 else { return "" }
        return Array(repeating: self, count: times).joined(separator: " ")
    }
}
