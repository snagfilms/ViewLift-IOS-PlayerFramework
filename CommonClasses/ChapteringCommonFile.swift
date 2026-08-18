//
//  ChapteringCommonFile.swift
//  ViewliftPlayerSampleApp
//
//  Created by Devendra Gaur on 02/07/26.
//  Copyright © 2026 Viewlift. All rights reserved.
//
import UIKit
import Foundation
import SwiftUI
import VLPlayerLib


struct ChapteringCuePointResponse: Decodable {
    let items: Items

    enum CodingKeys: String, CodingKey {
        case items = "Items"
    }

    struct Items: Decodable {
        let segments: [ChapteringCuePoint]

        enum CodingKeys: String, CodingKey {
            case segments = "Segments"
        }
    }
}

struct ChapteringCuePoint: Codable {
    let startTime: Double
    let label: String
    let thumbnail: String?
    let eventStartUtc: String?
    let origLength: Double?
    let stocks: String?

    enum CodingKeys: String, CodingKey {
        case startTime = "StartTime"
        case label = "Label"
        case origLength = "OrigLength"
        case thumbnail = "OriginalThumbnailLocation"
        case eventStartUtc = "event_start_utc"
        case stocks = "Stocks"
    }
}


// MARK: - Chaptering JSON index lookup

/// Chaptering segments cached in the exact order declared in `chaptering.json` — i.e. before
/// any sorting or DVR-window filtering applied for display. Kept separate from
/// `loadChapterSegmentsFromJSON()` (which sorts and maps to the SDK model) so callers can
/// still resolve a cue point's true position in the source file.
private let chapteringRawJSONSegments: [ChapteringCuePoint] = {
    guard let url = Bundle.main.url(forResource: "chaptering", withExtension: "json"),
          let rawString = try? String(contentsOf: url, encoding: .utf8),
          let jsonStart = rawString.firstIndex(of: "{"),
          let data = String(rawString[jsonStart...]).data(using: .utf8) else {
        return []
    }
    do {
        return try JSONDecoder().decode(ChapteringCuePointResponse.self, from: data).items.segments
    } catch {
        debugPrint("Chaptering cue point parse error: \(error)")
        return []
    }
}()

/// Index of the JSON object in `chaptering.json` (its original file order) whose `StartTime`
/// matches `startTime`. This is the index that should be reported to `logLiveRecapSelection`
/// so analytics reflect the tapped item's real position in the source data, rather than its
/// position in a sorted/filtered on-screen list. Returns `0` when no match is found.
func chapterJSONIndex(forStartTime startTime: Double) -> Int {
    chapteringRawJSONSegments.firstIndex { $0.startTime == startTime } ?? 0
}

extension UIViewController{
    func todayDate(preservingTimeFrom timeText: String?) -> Date? {
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
    
    func chapteringDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }
    
}

// MARK: - Shared chaptering host

/// Single home for all chaptering logic shared between the iOS and tvOS player
/// screens. Both `PlayerViewController_iOS` and `PlayerViewController_tvOS` conform
/// to this protocol; the shared behaviour lives in the extension below and any
/// platform-specific work is guarded with `#if os(iOS)` / `#if os(tvOS)` rather than
/// duplicated per platform.
protocol ChapteringHosting: UIViewController {
    var vlPlayer: VLPlayer? { get }
    var isChapteringCuePointEnable: Bool { get }
    /// Source of truth for both the slider markers and the platform chaptering UI.
    var chapterCuePointSegments: [VLPlayer.ChapteringCuePoint] { get set }

    #if os(iOS)
    var isChapterButtonAction: Bool { get set }
    var liveMomentsHostingController: UIHostingController<LiveMomentsTabsView>? { get set }
    var playerContainerView: UIView { get }
    /// The player controls configuration the user picks in the chaptering popup. The host
    /// reads this back in its feature-support builder so the selection drives which
    /// `playerControlsViewConfiguration` is applied.
    var selectedPlayerControlsConfiguration: PlayerControlsConfigurationOption { get set }
    func updateChapterButtonAppearance()
    /// Tears down and rebuilds the player so a newly selected controls configuration is
    /// applied instantly. Implemented by the host since only it owns the player lifecycle.
    func reloadPlayerForSelectedControlsConfiguration()
    #elseif os(tvOS)
    var videoPlayerControlsView: VLCustomPlayerControlsView? { get }
    var playerContainerView: UIView { get }
    var testButton: UIButton { get }
    var isFullScreen: Bool { get }
    var useCustomThemeControls: Bool { get }
    func applyChapteringFeatureConfiguration(chapteringEnabled: Bool, useCustomThemeControls: Bool)
    #endif
}

// MARK: - Shared chaptering logic (both platforms)

extension ChapteringHosting {

    /// Loads the bundled `chaptering.json` cue points as SDK models. Shared by both
    /// platforms so the source data and parsing stay identical.
    func loadChapterSegmentsFromJSON() -> [VLPlayer.ChapteringCuePoint] {
        guard let url = Bundle.main.url(forResource: "chaptering", withExtension: "json"),
              let rawString = try? String(contentsOf: url, encoding: .utf8),
              let jsonStart = rawString.firstIndex(of: "{") else {
            return []
        }

        let jsonString = String(rawString[jsonStart...])
        guard let data = jsonString.data(using: .utf8) else { return [] }

        do {
            let response = try JSONDecoder().decode(ChapteringCuePointResponse.self, from: data)
            return response.items.segments
                .sorted { $0.startTime < $1.startTime }
                .map {
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

    /// Re-anchors every cue point's `event_start_utc` to today at `baseDate`: the earliest
    /// cue point is pinned to that moment and the rest are shifted by the same delta so the
    /// relative spacing is preserved. Returns `false` when there is no cue point with a
    /// parsable `event_start_utc` to anchor against.
    @discardableResult
    func reanchorChapterCuePoints(toBaseDate baseDate: Date) -> Bool {
        let formatter = chapteringDateFormatter()
        let originalDates = chapterCuePointSegments.compactMap { cue in
            cue.eventStartUtc.flatMap { formatter.date(from: $0) }
        }
        guard let earliestDate = originalDates.min() else { return false }

        let shift = baseDate.timeIntervalSince(earliestDate)
        chapterCuePointSegments = chapterCuePointSegments.map { cue in
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
        return true
    }

    /// Pushes the current cue points to the SDK, which recalculates their positions inside
    /// the current DVR window (`event_start_utc + startTime`), then refreshes the platform
    /// chaptering UI so both show only cue points inside the window.
    func configureSDKChapterSegments() {
        #if os(iOS)
        vlPlayer?.setChapteringCuePoints(chapterCuePointSegments)
        vlPlayer?.setChapterCueConfig(chapterCueConfig)
        refreshLiveMoments()
        #elseif os(tvOS)
        videoPlayerControlsView?.configureChapteringCuePoints(appModelChapterCuePoints)
        vlPlayer?.updateChapteringCuePoints(chapterCuePointSegments)
        #endif
    }

    /// Lightweight alert used by the time-entry flow on both platforms.
    func presentChapteringAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - iOS-specific chaptering UI

#if os(iOS)
/// Player controls configuration options a user can pick from the chaptering popup.
/// Kept independent of the host's internal configuration enum so the shared chaptering
/// layer stays decoupled from any single view controller (Dependency Inversion).
enum PlayerControlsConfigurationOption: CaseIterable {
    case custom
    case customTheme

    /// User-facing title shown in the selection control.
    var title: String {
        switch self {
        case .custom:
            return "Custom"
        case .customTheme:
            return "Custom Theme"
        }
    }
}

extension ChapteringHosting {

    var chapterCueConfig: VLPlayer.ChapterCueConfig {
        VLPlayer.ChapterCueConfig(
            cueColor: .white,
            cueWidth: 8,
            cueHeight: 8,
            isCueCircular: true,
            showChapterTitleTillCuePoint: true
        )
    }

    /// Presents a popup for the user to enter the live stream's event-start time (UTC, HH:MM).
    ///
    /// On Apply, each cue point's `event_start_utc` is re-anchored to today's date at the
    /// entered UTC time, then pushed to `configureSDKChapterSegments()`, which recalculates
    /// every cue point against the current DVR window and refreshes both the slider markers
    /// and the Live Moments list. Only cue points whose `event_start_utc + startTime` falls
    /// inside the window are shown.
    func showChapterTimeEntryPopup() {
        guard isChapteringCuePointEnable else { return }

        let alert = UIAlertController(
            title: "Stream Start Time (UTC)",
            message: "Enter today's live-stream start time in UTC (HH:MM).\n\nSelect the player controls configuration to apply.\n\n",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "HH:MM  (UTC)"
            textField.keyboardType = .numbersAndPunctuation
            textField.clearButtonMode = .whileEditing
        }

        let configurationControl = makePlayerControlsConfigurationControl()
        alert.view.addSubview(configurationControl)
        NSLayoutConstraint.activate([
            configurationControl.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 16),
            configurationControl.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -16),
            configurationControl.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -140)
        ])

        let applyAction = UIAlertAction(title: "Apply", style: .default) { [weak self, weak alert, weak configurationControl] _ in
            guard let self = self else { return }
            let previousConfiguration = self.selectedPlayerControlsConfiguration
            if let selectedIndex = configurationControl?.selectedSegmentIndex,
               PlayerControlsConfigurationOption.allCases.indices.contains(selectedIndex) {
                self.selectedPlayerControlsConfiguration = PlayerControlsConfigurationOption.allCases[selectedIndex]
            }
            let didChangeConfiguration = previousConfiguration != self.selectedPlayerControlsConfiguration
            guard let text = alert?.textFields?.first?.text,
                  let baseDate = self.todayDate(preservingTimeFrom: text) else {
                self.presentChapteringAlert(title: "Invalid Time", message: "Please enter a valid time in HH:MM (UTC) format.")
                return
            }
            guard self.reanchorChapterCuePoints(toBaseDate: baseDate) else {
                self.presentChapteringAlert(title: "No Cue Points", message: "No chapter cue points with event_start_utc are available.")
                return
            }

            self.isChapterButtonAction = true
            self.updateChapterButtonAppearance()
            self.setupLiveMomentsSection()
            // A controls-configuration change requires a fresh player so the new controls
            // view is built from the updated feature support; otherwise just push the
            // re-anchored cue points to the existing player.
            if didChangeConfiguration {
                self.reloadPlayerForSelectedControlsConfiguration()
            } else {
                self.configureSDKChapterSegments()
            }
        }

        alert.addAction(applyAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    /// Builds the segmented control that lets the user pick between the available player
    /// controls configurations, pre-selecting the currently stored option.
    private func makePlayerControlsConfigurationControl() -> UISegmentedControl {
        let control = UISegmentedControl(items: PlayerControlsConfigurationOption.allCases.map { $0.title })
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = PlayerControlsConfigurationOption.allCases
            .firstIndex(of: selectedPlayerControlsConfiguration) ?? 0
        return control
    }

    /// Disables SDK chapter cues and removes the Live Moments panel.
    func disableChaptering() {
        liveMomentsHostingController?.willMove(toParent: nil)
        liveMomentsHostingController?.view.removeFromSuperview()
        liveMomentsHostingController?.removeFromParent()
        liveMomentsHostingController = nil
    }

    func setupLiveMomentsSection() {
        guard liveMomentsHostingController == nil else { return }
        let liveMomentsView = LiveMomentsTabsView(
            model: LiveMomentsModel(tabs: liveMomentsTabs)
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
                    startTimeLabel: formatMomentTime(
                        secondsAgo: mapping.windowDuration - mapping.windowPosition
                    ),
                    seekSeconds: mapping.cuePoint.startTime
                )
            }
        return [LiveMomentsTabItem(title: "Live Moments", moments: liveMoments)]
    }

    /// Syncs the Live Moments list with the SDK's current DVR-window cue-point mapping.
    /// Called on playback progress (every second). We always push the latest mapping into
    /// the observable model so the list can never get stuck empty after a player/UI reload
    /// (when the SDK window is briefly unavailable and comes back). This does NOT reload the
    /// whole list: the hosting controller's `rootView` is stable and SwiftUI diffs the
    /// `ForEach` by each moment's stable id, so unchanged rows are left untouched and only
    /// the chapters that entered or left the window are inserted/removed. When no cue point's
    /// air time falls inside the window the panel is hidden, mirroring the empty slider.
    func refreshLiveMoments() {
        guard isChapteringCuePointEnable, let hostingController = liveMomentsHostingController else { return }
        let newTabs = liveMomentsTabs
        let hasMoments = newTabs.contains { $0.moments.isEmpty == false }
        // The SDK returns an empty window mapping while the DVR window is briefly unresolvable
        // (e.g. while a tapped chapter seek buffers). Ignore those transient empties so the list
        // isn't cleared and rebuilt ("reloaded") on tap. Real membership changes (a chapter
        // entering/leaving) always return a non-empty window set, so SwiftUI still diffs by
        // stable id and inserts/removes just the affected row.
        guard hasMoments else { return }
        hostingController.rootView.model.tabs = newTabs
        setLiveMomentsVisibility(isHidden: false)
    }

    func playerSeekForLiveMoments(seconds: Double) {
        vlPlayer?.seekToChapter(startTime: seconds)
        vlPlayer?.logLiveRecapSelection(startTime: seconds, index: chapterJSONIndex(forStartTime: seconds))
    }

    private func formatMomentTime(secondsAgo: Double) -> String {
        let elapsedSeconds = max(0, Int(secondsAgo.rounded(.down)))
        if elapsedSeconds < 60 {
            return "\(elapsedSeconds)s ago"
        }
        if elapsedSeconds < 3_600 {
            return "\(elapsedSeconds / 60)m ago"
        }
        return "\(elapsedSeconds / 3_600)h ago"
    }
}
#endif

// MARK: - tvOS-specific chaptering UI

#if os(tvOS)
private enum ChapteringTimeEntry {
    static let textFieldTag = 990_001
    static let placeholder = "HH:mm"
}

/// Two SwiftUI toggles (styled like `WatchHistoryView`) for the tvOS chaptering panel:
/// one enables/disables chaptering, the other switches the controls skin
/// (On = `.customTheme`, Off = `.custom`). Any change calls `onChange` with both values.
private struct ChapteringFeatureTogglesView: View {
    @State var chapteringEnabled: Bool
    @State var useCustomThemeControls: Bool
    let onChange: (_ chapteringEnabled: Bool, _ useCustomThemeControls: Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Chaptering enable")
                    .font(.system(size: 22))
                    .foregroundColor(.primary)

                Toggle("", isOn: $chapteringEnabled)
                    .labelsHidden()
                    .tint(.green)
                    .onChange(of: chapteringEnabled) { newValue in
                        onChange(newValue, useCustomThemeControls)
                    }
                    .foregroundColor(.primary)
            }

            HStack {
                Text("Custom controls")
                    .font(.system(size: 22))
                    .foregroundColor(.primary)

                Toggle("", isOn: $useCustomThemeControls)
                    .labelsHidden()
                    .tint(.green)
                    .onChange(of: useCustomThemeControls) { newValue in
                        onChange(chapteringEnabled, newValue)
                    }
                    .foregroundColor(.primary)
            }
        }
    }
}

extension ChapteringHosting {

    /// App-model cue points for `VLCustomPlayerControlsView`, which renders the tvOS chapter
    /// collection from the app-level `ChapteringCuePoint` model.
    var appModelChapterCuePoints: [ChapteringCuePoint] {
        chapterCuePointSegments.map {
            ChapteringCuePoint(startTime: $0.startTime,
                               label: $0.label,
                               thumbnail: $0.thumbnail,
                               eventStartUtc: $0.eventStartUtc,
                               origLength: $0.origLength,
                               stocks: $0.stocks)
        }
    }

    /// Small-screen-only control that lets the user type a time (HH:mm). The date is set to
    /// today while the typed time is preserved, and the result updates the cue points'
    /// `event_start_utc`.
    func setupChapteringTimeEntry() {
        guard isChapteringCuePointEnable else { return }
        guard view.viewWithTag(ChapteringTimeEntry.textFieldTag) == nil else { return }

        let titleLabel = UILabel()
        titleLabel.text = "Live recap start time"
        titleLabel.textColor = .label
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
        applyButton.addAction(UIAction { [weak self] _ in
            self?.applyChapteringTimeEntry()
        }, for: .primaryActionTriggered)

        // Toggle 1: enable/disable chaptering cue points.
        // Toggle 2: choose the controls skin (On = .customTheme, Off = .custom).
        let togglesView = ChapteringFeatureTogglesView(
            chapteringEnabled: isChapteringCuePointEnable,
            useCustomThemeControls: useCustomThemeControls
        ) { [weak self] chapteringEnabled, useCustomThemeControls in
            self?.applyChapteringFeatureConfiguration(
                chapteringEnabled: chapteringEnabled,
                useCustomThemeControls: useCustomThemeControls
            )
        }
        let togglesHost = UIHostingController(rootView: togglesView)
        togglesHost.view.backgroundColor = .clear
        togglesHost.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(togglesHost)
        togglesHost.didMove(toParent: self)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, textField, applyButton, togglesHost.view])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isHidden = isFullScreen
        stackView.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.15, alpha: 1.0)
                : UIColor(white: 0.95, alpha: 1.0)
        }
        stackView.layer.cornerRadius = 12
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20, leading: 24, bottom: 20, trailing: 24)
        view.addSubview(stackView)

        // Position the fields in the middle of the gap between the player view
        // (left) and the remote/test button (right), vertically aligned with them.
        let middleGuide = UILayoutGuide()
        view.addLayoutGuide(middleGuide)

        NSLayoutConstraint.activate([
            middleGuide.leadingAnchor.constraint(equalTo: playerContainerView.trailingAnchor),
            middleGuide.trailingAnchor.constraint(equalTo: testButton.leadingAnchor),
            stackView.centerXAnchor.constraint(equalTo: middleGuide.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: playerContainerView.centerYAnchor)
        ])
    }

    /// Keeps the time-entry control visible only in the non-full-screen player.
    func updateChapteringTimeEntryVisibility() {
        view.viewWithTag(ChapteringTimeEntry.textFieldTag)?.superview?.isHidden = isFullScreen
    }

    func applyChapteringTimeEntry() {
        guard isChapteringCuePointEnable else { return }
        guard let textField = view.viewWithTag(ChapteringTimeEntry.textFieldTag) as? UITextField,
              let baseDate = todayDate(preservingTimeFrom: textField.text) else {
            presentChapteringAlert(title: "Invalid Time", message: "Please enter a valid time in HH:mm format.")
            return
        }
        guard reanchorChapterCuePoints(toBaseDate: baseDate) else { return }

        // Recalculate against the current DVR window and refresh the slider / chapter collection.
        configureSDKChapterSegments()

        let updatedFirst = chapterCuePointSegments.first?.eventStartUtc ?? ""
        presentChapteringAlert(title: "Time Updated", message: "First live recap starts at \(updatedFirst).")
    }
}
#endif
