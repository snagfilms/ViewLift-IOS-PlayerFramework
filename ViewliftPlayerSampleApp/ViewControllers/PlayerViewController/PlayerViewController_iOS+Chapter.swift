//
//  PlayerViewController_iOS+Chapter.swift
//  ViewliftPlayerSampleApp
//
//  Created by Amit Pandey on 27/05/26.
//  Copyright © 2026 Viewlift. All rights reserved.
//


import Foundation
import VLPlayerLib
import UIKit
import SwiftUI

// All chaptering logic is shared with tvOS via `ChapteringHosting`
// (see CommonClasses/ChapteringCommonFile.swift). This file only declares
// conformance; platform-specific behaviour lives behind `#if os(iOS)` there.
extension PlayerViewController_iOS: ChapteringHosting {}
