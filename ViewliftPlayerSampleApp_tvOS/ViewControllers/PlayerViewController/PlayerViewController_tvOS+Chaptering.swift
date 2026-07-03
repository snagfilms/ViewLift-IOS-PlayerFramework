//
//  PlayerViewController_tvOS+Chaptering.swift
//  ViewliftPlayerSampleApp
//
//  Created by devendragaur@viewlift.com on 25/06/26.
//  Copyright © 2026 Viewlift. All rights reserved.
//

import UIKit
import VLPlayerLib

// All chaptering logic is shared with iOS via `ChapteringHosting`
// (see CommonClasses/ChapteringCommonFile.swift). This file only declares
// conformance; platform-specific behaviour lives behind `#if os(tvOS)` there.
extension PlayerViewController_tvOS: ChapteringHosting {}
