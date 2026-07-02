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

    /// Presents a popup for the user to enter the live stream's event-start time in UTC.
    ///
    /// ## How cue-point positioning works
    ///   Reference point : UTC midnight today  (eventStartUTC for every segment)
    ///   Adjusted startTime = JSON.startTime + enteredUTCSeconds
    ///
    ///   SDK then computes:
    ///     liveElapsed  = Date().timeIntervalSince(midnight)  ← seconds since midnight
    ///     windowStart  = max(0, liveElapsed - dvrWindowDuration)
    ///     cue position = adjustedStartTime - windowStart     (if in [windowStart, liveElapsed])
    ///     seekbar x%   = cue position / dvrWindowDuration
    ///
    /// ## Why this places chapters near the live edge
    ///   User enters 15:10:00 UTC → offset = 54 600 s
    ///   Chapter JSON.startTime 1200 → adjusted = 55 800 s
    ///   At 15:31 UTC: liveElapsed ≈ 55 860 s, windowStart ≈ 54 060 s (30-min DVR)
    ///   Position = (55 800 − 54 060) / 1800 = 96.7 %  → near RIGHT edge ✓
    ///   5 min later: windowStart ≈ 54 360 s → position = 80 %  → moved LEFT ✓
    func showChapterTimeEntryPopup() {
        let alert = UIAlertController(
            title: "Stream Start Time (UTC)",
            message: "Enter the time the live stream started today, in UTC (HH:MM:SS).\nMust be a time that has already passed.",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "HH:MM:SS  (UTC)"
            textField.keyboardType = .numbersAndPunctuation
            textField.clearButtonMode = .whileEditing
        }

        let applyAction = UIAlertAction(title: "Apply", style: .default) { [weak self, weak alert] _ in
            guard
                let self = self,
                let text = alert?.textFields?.first?.text,
                !text.trimmingCharacters(in: .whitespaces).isEmpty,
                let utcSeconds = self.parseTimeString(text)
            else {
                self?.showAlert(title: "Invalid Input", message: "Please enter a valid time (HH:MM:SS or seconds).")
                return
            }

            // Validate that the entered time-of-day has already passed today in UTC.
            var utcCalendar = Calendar(identifier: .gregorian)
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            let midnightUTC = utcCalendar.startOfDay(for: Date())
            let enteredUTCDate = midnightUTC.addingTimeInterval(utcSeconds)

            guard enteredUTCDate < Date() else {
                self.showAlert(
                    title: "Time is in the Future",
                    message: "Enter a UTC time that has already passed today so chapters can appear in the DVR window."
                )
                return
            }

            // Store the raw seconds-from-midnight offset.
            // makeChapterSegment() will add this to each JSON startTime and use
            // midnight UTC as the common eventStartUTC reference, which keeps every
            // adjusted startTime close to the current liveElapsed value so cues
            // appear near the live (right) edge and drift left over time.
            self.chapterUTCSecondsOffset = utcSeconds

            self.isChapteringEnabled = true
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
        vlPlayer?.setChapterEnabled(false)
        liveMomentsHostingController?.willMove(toParent: nil)
        liveMomentsHostingController?.view.removeFromSuperview()
        liveMomentsHostingController?.removeFromParent()
        liveMomentsHostingController = nil
        chapterUTCSecondsOffset = nil
    }

    /// Parses a time string into total seconds.
    /// Accepted formats: "HH:MM:SS", "MM:SS", or plain integer/decimal seconds.
    private func parseTimeString(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: ":").compactMap { Double($0) }
        switch parts.count {
        case 1:
            return parts[0]
        case 2:
            return parts[0] * 60 + parts[1]
        case 3:
            return parts[0] * 3_600 + parts[1] * 60 + parts[2]
        default:
            return nil
        }
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
    }

    func setLiveMomentsVisibility(isHidden: Bool) {
        liveMomentsHostingController?.view.isHidden = isHidden
    }

    var liveMomentsTabs: [LiveMomentsTabItem] {
        // segment.startTime is UTC-adjusted (jsonStartTime + chapterUTCSecondsOffset) so the
        // SDK can position cue markers on the live seekbar relative to UTC midnight.
        // For seeking and display we need the original event-relative position, so we
        // subtract the offset back.  When no offset is set the subtraction is a no-op.
        let offset = chapterUTCSecondsOffset ?? 0
        let liveMoments = chapterSegments
            .sorted { $0.startTime < $1.startTime }
            .map { segment in
                let eventRelativeSeconds = segment.startTime - offset
                return LiveMomentItem(
                    thumbnailAssetName: "live_moments",
                    title: segment.label,
                    startTimeLabel: formatMomentTime(seconds: segment.startTime),
                    seekSeconds: segment.startTime
                )
            }
        return [LiveMomentsTabItem(title: "Live Moments", moments: liveMoments)]
    }

    var chapterSegments: [VLPlayer.ChapterSegment] {
        loadChapterSegmentsFromJSON() ?? fallbackChapterSegments()
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
        vlPlayer?.setChapterEnabled(true)
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

    private func loadChapterSegmentsFromJSON() -> [VLPlayer.ChapterSegment]? {
        guard let chapterJSONURL = Bundle.main.url(forResource: "chapter-json", withExtension: "json") else {
            print("Chapter file chapter-json.json not found in bundle.")
            return nil
        }

        do {
            let chapterData = try Data(contentsOf: chapterJSONURL)
            let payload = try JSONSerialization.jsonObject(with: chapterData) as? [String: Any]
            let items = payload?["Items"] as? [String: Any]
            let segmentDictionaries = items?["Segments"] as? [[String: Any]]

            guard let segmentDictionaries = segmentDictionaries else {
                print("Chapter JSON schema mismatch for Items.Segments.")
                return nil
            }

            let parsedSegments = segmentDictionaries.compactMap(makeChapterSegment(from:))
            guard !parsedSegments.isEmpty else {
                return nil
            }

            return parsedSegments.sorted { $0.startTime < $1.startTime }
        } catch {
            print("Failed to load chapter-json.json: \(error)")
            return nil
        }
    }

    private func makeChapterSegment(from payload: [String: Any]) -> VLPlayer.ChapterSegment? {
        guard
            let jsonStartTime = parseDouble(payload["StartTime"]),
            let label = payload["Label"] as? String
        else {
            return nil
        }

        // When the user has entered an event-start time, shift every startTime so it
        // is expressed as "seconds since UTC midnight today".  Using midnight as the
        // shared eventStartUTC keeps liveElapsed large and stable (≈ time-of-day in
        // seconds), so adjusted chapter times are close to liveElapsed and therefore
        // near the live (right) edge of the seekbar — moving leftward as the DVR
        // window advances.
        //
        // Without a user-supplied offset, fall back to the JSON's event_start_utc
        // and the unmodified startTime (original behaviour).
        let startTime: Double
        let eventStartDate: Date?

        if let offset = chapterUTCSecondsOffset {
            var utcCalendar = Calendar(identifier: .gregorian)
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            eventStartDate = utcCalendar.startOfDay(for: Date())   // midnight UTC today
            startTime = jsonStartTime + offset
        } else {
            eventStartDate = (payload["event_start_utc"] as? String)
                .flatMap { chapterDateFormatter.date(from: $0) }
            startTime = jsonStartTime
        }

        return VLPlayer.ChapterSegment(
            startTime: startTime,
            label: label,
            eventStartUTC: eventStartDate,
            originalClipLocation: parseString(payload["OriginalClipLocation"]),
            originalThumbnailLocation: parseString(payload["OriginalThumbnailLocation"]),
            optimizedClipLocation: parseString(payload["OptimizedClipLocation"]),
            optimizedThumbnailLocation: parseString(payload["OptimizedThumbnailLocation"]),
            featureCount: parseString(payload["FeatureCount"]),
            origLength: parseDouble(payload["OrigLength"]) ?? .zero,
            optoLength: parseDouble(payload["OptoLength"]) ?? .zero,
            optimizedDurationPerTrack: [],
            optoStartCode: parseString(payload["OptoStartCode"]),
            optoEndCode: parseString(payload["OptoEndCode"]),
            event: parseString(payload["Event"]),
            stocks: parseString(payload["Stocks"]),
            notableMoments: parseString(payload["NotableMoments"])
        )
    }

    private func parseString(_ value: Any?) -> String {
        value as? String ?? ""
    }

    private func parseDouble(_ value: Any?) -> Double? {
        switch value {
        case let number as NSNumber:
            return number.doubleValue
        case let text as String:
            return Double(text)
        default:
            return nil
        }
    }

    private func fallbackChapterSegments() -> [VLPlayer.ChapterSegment] {
        let eventStartDate = chapterDateFormatter.date(from: "2026-06-19T05:57:00Z")
        return [
            VLPlayer.ChapterSegment(startTime: 60, label: "CNBC Preview one", eventStartUTC: eventStartDate, originalClipLocation: "", originalThumbnailLocation: "", optimizedClipLocation: "", optimizedThumbnailLocation: "", featureCount: "", origLength: 150, optoLength: 1.0, optimizedDurationPerTrack: [], optoStartCode: "", optoEndCode: "", event: "", stocks: "", notableMoments: ""),
            VLPlayer.ChapterSegment(startTime: 600, label: "CNBC Preview one", eventStartUTC: eventStartDate, originalClipLocation: "", originalThumbnailLocation: "", optimizedClipLocation: "", optimizedThumbnailLocation: "", featureCount: "", origLength: 630, optoLength: 1.0, optimizedDurationPerTrack: [], optoStartCode: "", optoEndCode: "", event: "", stocks: "", notableMoments: ""),
            VLPlayer.ChapterSegment(startTime: 1200, label: "CNBC Preview two", eventStartUTC: eventStartDate, originalClipLocation: "", originalThumbnailLocation: "", optimizedClipLocation: "", optimizedThumbnailLocation: "", featureCount: "", origLength: 1250.0, optoLength: 1.0, optimizedDurationPerTrack: [], optoStartCode: "", optoEndCode: "", event: "", stocks: "", notableMoments: ""),
            VLPlayer.ChapterSegment(startTime: 2400, label: "CNBC Preview three", eventStartUTC: eventStartDate, originalClipLocation: "", originalThumbnailLocation: "", optimizedClipLocation: "", optimizedThumbnailLocation: "", featureCount: "", origLength: 2480.0, optoLength: 1.0, optimizedDurationPerTrack: [], optoStartCode: "", optoEndCode: "", event: "", stocks: "", notableMoments: "")
        ]
    }

    private var chapterDateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

}

