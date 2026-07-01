//
//  PlayerViewController_tvOS+Chaptering.swift
//  ViewliftPlayerSampleApp
//
//  Created by devendragaur@viewlift.com on 25/06/26.
//  Copyright © 2026 Viewlift. All rights reserved.
//

import UIKit
import VLPlayerLib

extension PlayerViewController_tvOS {

    private enum ChapteringTimeEntry {
        static let textFieldTag = 990_001
        static let placeholder = "HH:mm"
    }

    // Small-screen-only control that lets the user type a time (HH:mm). The date is
    // automatically set to today while the typed time is preserved, and the resulting
    // date-time is used to update the chaptering cue points' event_start_utc.
    func setupChapteringTimeEntry() {
        guard isChapteringCuePointEnable else { return }
        guard view.viewWithTag(ChapteringTimeEntry.textFieldTag) == nil else { return }

        let titleLabel = UILabel()
        titleLabel.text = "Live recap start time"
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)

        let textField = UITextField()
        textField.tag = ChapteringTimeEntry.textFieldTag
        textField.placeholder = ChapteringTimeEntry.placeholder
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.keyboardType = .numbersAndPunctuation
        textField.widthAnchor.constraint(equalToConstant: 220).isActive = true

        let applyButton = UIButton(type: .system)
        applyButton.setTitle("Apply Time", for: .normal)
        applyButton.setTitleColor(.black, for: .normal)
        applyButton.addTarget(self, action: #selector(applyChapteringTimeTapped), for: .primaryActionTriggered)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, textField, applyButton])
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isHidden = isFullScreen
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: testButton.trailingAnchor)
        ])
    }

    @objc private func applyChapteringTimeTapped() {
        guard isChapteringCuePointEnable else { return }
        guard let textField = view.viewWithTag(ChapteringTimeEntry.textFieldTag) as? UITextField,
              let baseDate = todayDate(preservingTimeFrom: textField.text) else {
            showAlert(title: "Invalid Time", message: "Please enter a valid time in HH:mm format.")
            return
        }

        let formatter = chapteringDateFormatter()
        let originalDates = chapteringCuePoints.compactMap { cue in
            cue.eventStartUtc.flatMap { formatter.date(from: $0) }
        }
        guard let earliestDate = originalDates.min() else { return }

        // Anchor the earliest segment to today + entered time and shift the rest by the
        // same delta so the relative spacing between segments is preserved.
        let shift = baseDate.timeIntervalSince(earliestDate)
        chapteringCuePoints = chapteringCuePoints.map { cue in
            guard let eventStartUtc = cue.eventStartUtc,
                  let eventDate = formatter.date(from: eventStartUtc) else {
                return cue
            }
            let updatedUtc = formatter.string(from: eventDate.addingTimeInterval(shift))
            return ChapteringCuePoint(startTime: cue.startTime,
                                      label: cue.label,
                                      thumbnail: cue.thumbnail,
                                      eventStartUtc: updatedUtc,
                                      stocks: cue.stocks)
        }
        // Refresh the app-side custom controls (when used) and push the updated
        // array to the SDK so its slider/chaptering UI refreshes with the latest data.
        videoPlayerControlsView?.configureChapteringCuePoints(chapteringCuePoints)
        vlPlayer?.updateChapteringCuePoints(chapteringCuePoints.map {
            VLPlayer.ChapteringCuePoint(startTime: $0.startTime,
                                        label: $0.label,
                                        thumbnail: $0.thumbnail,
                                        eventStartUtc: $0.eventStartUtc,
                                        stocks: $0.stocks)
        })

        let updatedFirst = chapteringCuePoints.first?.eventStartUtc ?? ""
        showAlert(title: "Time Updated", message: "First live recap starts at \(updatedFirst).")
    }

    // Builds today's date (in UTC) using the HH:mm time entered by the user.
    private func todayDate(preservingTimeFrom timeText: String?) -> Date? {
        guard let timeText = timeText?.trimmingCharacters(in: .whitespaces), !timeText.isEmpty else {
            return nil
        }
        let components = timeText.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]), (0...23).contains(hour),
              let minute = Int(components[1]), (0...59).contains(minute) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = 0
        return calendar.date(from: dateComponents)
    }

    private func chapteringDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }
}
