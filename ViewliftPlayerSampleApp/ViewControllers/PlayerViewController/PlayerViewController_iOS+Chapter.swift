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

// MARK: - Deeplink Seek Handling
extension PlayerViewController_iOS {

    private func playerSeekForLiveMoments(seconds: Double) {
        guard let player = vlPlayer else {
            pendingDeepLinkSeekSeconds = seconds
            return
        }
//        let didSeek = player.seekToChapter(startTime: seconds)
        player.seekTo(seconds: seconds)
//        pendingDeepLinkSeekSeconds = didSeek ? nil : seconds
    }
}

// MARK: - Live Moments
extension PlayerViewController_iOS {
    func setupLiveMomentsSection() {
        guard liveMomentsHostingController == nil else { return }
        let liveMomentsView = LiveMomentsTabsView(
            tabs: liveMomentsTabs
        ) { [weak self] seekSeconds in
            self?.playerSeekForLiveMoments(seconds: seekSeconds)
        }
        let hostingController = UIHostingController(rootView: liveMomentsView)
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: playerContainerView.bottomAnchor, constant: Constants.liveMomentsTopSpacing),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.liveMomentsHorizontalInset),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.liveMomentsHorizontalInset),
            hostingController.view.heightAnchor.constraint(equalToConstant: Constants.liveMomentsHeight),
            hostingController.view.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.liveMomentsTopSpacing)
        ])
        hostingController.didMove(toParent: self)
        liveMomentsHostingController = hostingController
    }

    func setLiveMomentsVisibility(isHidden: Bool) {
        liveMomentsHostingController?.view.isHidden = isHidden
    }

    var liveMomentsTabs: [LiveMomentsTabItem] {
        let liveMoments = chapterSegments
            .sorted { $0.startTime < $1.startTime }
            .map { segment in
                LiveMomentItem(
                    thumbnailAssetName: "live_moments",
                    title: segment.label,
                    startTimeLabel: formatMomentTime(seconds: segment.startTime),
                    seekSeconds: segment.startTime
                )
            }
        return [LiveMomentsTabItem(title: "Live Moments", moments: liveMoments)]
    }

    var chapterSegments: [VLPlayer.ChapterSegment] {
        let eventStartUTC = "2026-06-19T05:57:00Z"//"2026-06-12T06:35:00Z"//"2026-07-12T17:00:00Z"
        
        let eventStartDate = ISO8601DateFormatter().date(from: eventStartUTC)
        return [
            VLPlayer.ChapterSegment(startTime: 120, label: "CNBC Preview one", eventStartUTC: eventStartDate, originalClipLocation: "", originalThumbnailLocation: "", optimizedClipLocation: "", optimizedThumbnailLocation: "", featureCount: "", origLength: 150, optoLength: 1.0, optimizedDurationPerTrack: [], optoStartCode: "", optoEndCode: "", event: "", stocks: "", notableMoments: ""),
            VLPlayer.ChapterSegment(startTime: 600, label: "CNBC Preview one", eventStartUTC: eventStartDate, originalClipLocation: "", originalThumbnailLocation: "", optimizedClipLocation: "", optimizedThumbnailLocation: "", featureCount: "", origLength: 630, optoLength: 1.0, optimizedDurationPerTrack: [], optoStartCode: "", optoEndCode: "", event: "", stocks: "", notableMoments: ""),
            VLPlayer.ChapterSegment(startTime: 1200, label: "CNBC Preview two", eventStartUTC: eventStartDate, originalClipLocation: "", originalThumbnailLocation: "", optimizedClipLocation: "", optimizedThumbnailLocation: "", featureCount: "", origLength: 1250.0, optoLength: 1.0, optimizedDurationPerTrack: [], optoStartCode: "", optoEndCode: "", event: "", stocks: "", notableMoments: ""),
            VLPlayer.ChapterSegment(startTime: 2400, label: "CNBC Preview three", eventStartUTC: eventStartDate, originalClipLocation: "", originalThumbnailLocation: "", optimizedClipLocation: "", optimizedThumbnailLocation: "", featureCount: "", origLength: 2480.0, optoLength: 1.0, optimizedDurationPerTrack: [], optoStartCode: "", optoEndCode: "", event: "", stocks: "", notableMoments: "")
        ]
    }

    var chapterCueConfig: VLPlayer.ChapterCueConfig {
        VLPlayer.ChapterCueConfig(
            cueColor: .white,
            cueWidth: 8,
            cueHeight: 8,
            isCueCircular: true,
            showChapterTitleTillCuePoint: true
        )
    }

    func configureSDKChapterSegments() {
        vlPlayer?.setChapterEnabled(false)
        vlPlayer?.setChapterCueConfig(chapterCueConfig)
        vlPlayer?.setChapterSegments(chapterSegments)
    }

    private func formatMomentTime(seconds: Double) -> String {
        let boundedValue = max(0, Int(seconds.rounded()))
        let hours = boundedValue / 3600
        let minutes = (boundedValue % 3600) / 60
        let secs = boundedValue % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

}

