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

// MARK: - Chapter Toggle / Time-Entry Popup
extension PlayerViewController_iOS {

    /// Presents a popup for the user to enter the live stream's event-start time (UTC, HH:MM).
    ///
    /// On Apply, each cue point's `event_start_utc` is re-anchored to today's date at the
    /// entered UTC time: the earliest cue point is pinned to that moment and the rest are
    /// shifted by the same delta so their relative spacing is preserved. The updated array is
    /// pushed to `configureSDKChapterSegments()`, which recalculates every cue point against the
    /// current DVR window and refreshes both the slider markers and the Live Moments list. Only
    /// cue points whose `event_start_utc + startTime` falls inside the window are shown.
    func showChapterTimeEntryPopup() {
        guard isChapteringCuePointEnable else { return }

        let alert = UIAlertController(
            title: "Stream Start Time (UTC)",
            message: "Enter today's live-stream start time in UTC (HH:MM).",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "HH:MM  (UTC)"
            textField.keyboardType = .numbersAndPunctuation
            textField.clearButtonMode = .whileEditing
        }

        let applyAction = UIAlertAction(title: "Apply", style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            guard let text = alert?.textFields?.first?.text,
                  let baseDate = self.todayDate(preservingTimeFrom: text) else {
                self.showAlert(title: "Invalid Time", message: "Please enter a valid time in HH:MM (UTC) format.")
                return
            }

            let formatter = self.chapteringDateFormatter()
            let originalDates = self.chapterCuePointSegments.compactMap { cue in
                cue.eventStartUtc.flatMap { formatter.date(from: $0) }
            }
            guard let earliestDate = originalDates.min() else {
                self.showAlert(title: "No Cue Points", message: "No chapter cue points with event_start_utc are available.")
                return
            }

            // Pin the earliest cue point to today + entered UTC time and shift the rest by the
            // same delta so the relative spacing between cue points is preserved.
            let shift = baseDate.timeIntervalSince(earliestDate)
            self.chapterCuePointSegments = self.chapterCuePointSegments.map { cue in
                guard let eventStartUtc = cue.eventStartUtc,
                      let eventDate = formatter.date(from: eventStartUtc) else {
                    return cue
                }
                let updatedUtc = formatter.string(from: eventDate.addingTimeInterval(shift))
                return VLPlayer.ChapteringCuePoint(startTime: cue.startTime,
                                                   label: cue.label,
                                                   thumbnail: cue.thumbnail,
                                                   origLength: cue.origLength,
                                                   eventStartUtc: updatedUtc,
                                                   stocks: cue.stocks)
            }

            self.isChapterButtonAction = true
            self.updateChapterButtonAppearance()
            self.setupLiveMomentsSection()
            self.configureSDKChapterSegments()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(applyAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    /// Disables SDK chapter cues and removes the Live Moments panel.
    func disableChaptering() {
        liveMomentsHostingController?.willMove(toParent: nil)
        liveMomentsHostingController?.view.removeFromSuperview()
        liveMomentsHostingController?.removeFromParent()
        liveMomentsHostingController = nil
    }
}

// MARK: - Deeplink Seek Handling
extension PlayerViewController_iOS {

    private func playerSeekForLiveMoments(seconds: Double) {
        guard let player = vlPlayer else {
//            pendingDeepLinkSeekSeconds = seconds
            return
        }
                player.seekToChapter(startTime: seconds)

//        player.seekTo(seconds: seconds)
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
        // Stay hidden until at least one cue point maps inside the current DVR window.
        let hasMoments = liveMomentsTabs.contains { $0.moments.isEmpty == false }
        setLiveMomentsVisibility(isHidden: !hasMoments)
    }

    func setLiveMomentsVisibility(isHidden: Bool) {
        liveMomentsHostingController?.view.isHidden = isHidden
    }

    var liveMomentsTabs: [LiveMomentsTabItem] {
        guard isChapteringCuePointEnable else {
            return [LiveMomentsTabItem(title: "Live Moments", moments: [])]
        }
        // Each cue point's air time (event_start_utc + startTime) is mapped into the current
        // DVR window by the SDK. We consume that mapping so the list mirrors the seekbar:
        // only cue points inside the window are shown, at their window-relative time. The raw
        // cue-point startTime is kept for seeking (seekToChapter re-maps it internally).
        let liveMoments = (vlPlayer?.chapteringCuePointsInCurrentWindow() ?? [])
            .map { mapping in
                LiveMomentItem(
                    thumbnailAssetName: "live_moments",
                    title: mapping.cuePoint.label,
                    startTimeLabel: formatMomentTime(seconds: mapping.windowPosition),
                    seekSeconds: mapping.cuePoint.startTime
                )
            }
        return [LiveMomentsTabItem(title: "Live Moments", moments: liveMoments)]
    }

    /// Rebuilds the Live Moments list from the SDK's current DVR-window cue-point mapping.
    /// Call on playback progress so the list tracks the sliding window (cue points appear /
    /// disappear and their times update as the live edge advances). Item ids are stable, so
    /// re-assigning the SwiftUI root view preserves selection and scroll position.
    ///
    /// When no cue point's air time (event_start_utc + startTime) falls inside the current DVR
    /// window, the panel is hidden so nothing is shown — mirroring the empty slider.
    func refreshLiveMoments() {
        guard isChapteringCuePointEnable, let hostingController = liveMomentsHostingController else { return }
        let tabs = liveMomentsTabs
        let hasMoments = tabs.contains { $0.moments.isEmpty == false }
        setLiveMomentsVisibility(isHidden: !hasMoments)
        hostingController.rootView = LiveMomentsTabsView(tabs: tabs) { [weak self] seekSeconds in
            self?.playerSeekForLiveMoments(seconds: seekSeconds)
        }
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

    /// Pushes the current cue points to the SDK, which recalculates their positions inside the
    /// current DVR window (`event_start_utc + startTime`) and refreshes the slider markers, then
    /// refreshes the Live Moments list so both show only cue points inside the window.
    func configureSDKChapterSegments() {
        vlPlayer?.setChapteringCuePoints(chapterCuePointSegments)
        vlPlayer?.setChapterCueConfig(chapterCueConfig)
        refreshLiveMoments()
    }

    private func formatMomentTime(seconds: Double) -> String {
        let boundedValue = max(0, Int(seconds.rounded()))
        let hours = boundedValue / 3600
        let minutes = (boundedValue % 3600) / 60
        let secs = boundedValue % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    func loadChapterSegmentsFromJSON() -> [VLPlayer.ChapteringCuePoint]? {
        guard let url = Bundle.main.url(forResource: "chaptering", withExtension: "json"),
              let rawString = try? String(contentsOf: url, encoding: .utf8),
              let jsonStart = rawString.firstIndex(of: "{") else {
            return []
        }

        let jsonString = String(rawString[jsonStart...])
        guard let data = jsonString.data(using: .utf8) else { return [] }

        do {
            let response = try JSONDecoder().decode(ChapteringCuePointResponse.self, from: data)
            let chapteringCuePoints = response.items.segments.sorted { $0.startTime < $1.startTime }
            return chapteringCuePoints.map {
                VLPlayer.ChapteringCuePoint(startTime: $0.startTime,
                                            label: $0.label,
                                            thumbnail: $0.thumbnail,
                                            origLength: $0.origLength,
                                            eventStartUtc: $0.eventStartUtc,
                                            stocks: $0.stocks)
            }
        } catch {
            debugPrint("Chaptering cue point parse error: \(error)")
            return []
        }
    }
}

