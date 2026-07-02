//
//  VLCustomPlayerControlsView+ChapteringSupport.swift
//  ViewliftPlayerSampleApp
//
//  Created by devendragaur@viewlift.com on 25/06/26.
//  Copyright © 2026 Viewlift. All rights reserved.
//

import UIKit
import Foundation

extension VLCustomPlayerControlsView {

    // MARK: - Show / hide geometry

    /// Bottom-constraint constant when the collection is tucked below the controls
    /// (only a small preview peeks in). Matches the value baked into the skin nib.
    private var chapteringCollapsedBottomConstant: CGFloat { -206 }

    /// Bottom-constraint constant when the collection is fully revealed.
    private var chapteringExpandedBottomConstant: CGFloat { 0 }

    // MARK: - DVR window helpers

    /// Start of the current DVR window (live edge minus the window length). Returns
    /// `nil` for non-DVR content, in which case cue points keep their static
    /// `startTime` offset.
    func chapteringWindowStartDate() -> Date? {
        guard isChapteringCuePointEnable, isDVRChaptering, chapteringDuration > 0 else { return nil }
        let liveEdgeDate = delegate?.getLiveEdgeDate() ?? Date()
        return liveEdgeDate.addingTimeInterval(-chapteringDuration)
    }

    /// Position of a cue point on the current timeline. For DVR it is re-anchored to
    /// the sliding window; otherwise it is the cue point's own `startTime`.
    func chapteringRelativeOffset(for cuePoint: ChapteringCuePoint) -> Double {
        if let windowStart = chapteringWindowStartDate(), let date = cuePoint.eventStartDate {
            return date.timeIntervalSince(windowStart)
        }
        return cuePoint.startTime
    }

    /// Cue points that fall inside the current timeline / DVR window.
    var visibleChapteringCuePoints: [ChapteringCuePoint] {
        guard chapteringDuration > 0 else { return [] }
        if let windowStart = chapteringWindowStartDate() {
            let windowEnd = windowStart.addingTimeInterval(chapteringDuration)
            return chapteringCuePoints.filter { cuePoint in
                guard let date = cuePoint.eventStartDate else { return false }
                return date >= windowStart && date <= windowEnd
            }
        }
        return chapteringCuePoints.filter { $0.startTime >= 0 && $0.startTime <= chapteringDuration }
    }

    /// Tolerance (in seconds) within which DVR playback is treated as being at the
    /// live edge, accounting for normal live latency / update jitter.
    private var chapteringLiveEdgeTolerance: Double{ 5 }


    /// Drives the DVR slider and time label for chaptering content. The thumb is
    /// pinned to the live position by default; once the user is behind live the time
    /// label shows the offset as a negative value (e.g. `-00:30`) and resets when the
    /// live edge is reached again.
    func updateChapteringDVRTime(currentTime: Double, totalTime: Double) {
        guard totalTime > 0 else { return }
        let behindLive = max(0, totalTime - currentTime)
        if behindLive <= chapteringLiveEdgeTolerance {
            sliderView.value = 1.0
        } else {
            sliderView.value = Float(min(max(currentTime / totalTime, 0), 1))
        }
        elapsedDurationLabel.text = chapteringDVRTimeText(currentTime: currentTime, totalTime: totalTime)
    }

    /// Time-label text for a given DVR position: `00:00` at (or near) the live edge,
    /// otherwise the offset behind live as a negative value (e.g. `-00:30`). Used both
    /// while playing and while the user is dragging the slider thumb.
    func chapteringDVRTimeText(currentTime: Double, totalTime: Double) -> String {
        guard totalTime > 0 else { return (0.0).getTimeInString() }
        let behindLive = max(0, totalTime - currentTime)
        if behindLive <= chapteringLiveEdgeTolerance {
            return (0.0).getTimeInString()
        }
        return "-" + behindLive.getTimeInString()
    }

    // MARK: - Chapter collection view

    /// Configures the chapter collection view that ships in the skin nib. It stays
    /// collapsed (a small preview) until focus moves into it, and only participates
    /// at all when chaptering is enabled.
    func setupChapteringCollectionView() {
        guard isChapteringCuePointEnable, let collectionView = chapteringCollectionView else { return }
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.remembersLastFocusedIndexPath = false
        collectionView.clipsToBounds = false
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 28
        }
        collectionView.register(
            UINib(nibName: ChapteringCuePointCell.reuseIdentifier, bundle: Bundle(for: ChapteringCuePointCell.self)),
            forCellWithReuseIdentifier: ChapteringCuePointCell.reuseIdentifier
        )
        collectionView.register(
            ChapteringEmptyStateCell.self,
            forCellWithReuseIdentifier: ChapteringEmptyStateCell.reuseIdentifier
        )
        chapteringCollectionBottomConstraint?.constant = chapteringCollapsedBottomConstant
        collectionView.isHidden = false
    }

    /// Hides or shows the chapter collection alongside the main player controls
    /// (e.g. when the settings / captions panel is opened, or when the controls are
    /// hidden). Guarded by the chaptering feature flag so it is a no-op otherwise.
    func setChapteringCollectionHidden(_ hidden: Bool) {
        guard isChapteringCuePointEnable, let collectionView = chapteringCollectionView else { return }
        collectionView.isHidden = hidden
        if hidden {
            setChapteringCollectionExpanded(false)
        }
    }

    /// Expands or collapses the collection using the nib's bottom constraint.
    func setChapteringCollectionExpanded(_ expanded: Bool) {
        guard isChapteringCuePointEnable, let constraint = chapteringCollectionBottomConstraint else { return }
        let target = expanded ? chapteringExpandedBottomConstant : chapteringCollapsedBottomConstant
        guard constraint.constant != target else { return }
        constraint.constant = target
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.layoutIfNeeded()
        }
    }

    /// Updates the play/pause visual on the standard skin's image view.
    func updatePlayPauseVisual(imageNamed name: String) {
        let image = UIImage(named: name)
        playPauseImageView?.isHidden = false
        playPauseImageView?.image = image
    }

    // MARK: - Cue point ingestion

    /// Replaces the chaptering cue points and refreshes the slider markers and the
    /// chapter collection. Safe to call repeatedly (e.g. when the host updates times).
    func configureChapteringCuePoints(_ cuePoints: [ChapteringCuePoint]) {
        guard isChapteringCuePointEnable else { return }
        chapteringCuePoints = cuePoints.sorted { $0.startTime < $1.startTime }
        // Force the next refresh to re-plot the slider and reload the collection.
        lastReloadedChapteringCuePointCount = -1
        updateChapteringCuePointsIfNeeded(duration: chapteringDuration)
    }

    /// Plots the visible cue points as slider dots and reloads the chapter
    /// collection. Called as the duration becomes known and on time updates.
    func updateChapteringCuePointsIfNeeded(duration: TimeInterval) {
        guard isChapteringCuePointEnable, duration > 0 else { return }
        let didChangeDuration = chapteringDuration != duration
        chapteringDuration = duration
        let cuePoints = visibleChapteringCuePoints
        sliderView.cuePointsUseDotStyle = true
        let didChangeCount = lastReloadedChapteringCuePointCount != cuePoints.count
        if didChangeDuration || didChangeCount {
            sliderView.setCuePoints(cuePoints: cuePoints.map { chapteringRelativeOffset(for: $0) }, duration: duration)
        }
        if didChangeCount {
            lastReloadedChapteringCuePointCount = cuePoints.count
            chapteringCollectionView?.reloadData()
        } else {
            updateVisibleChapteringCells()
        }
    }

    /// Keeps already-visible cells in sync without a full reload (used while the DVR
    /// window slides and cue-point offsets change).
    func updateVisibleChapteringCells() {
        guard let chapteringCollectionView else { return }
        let cuePoints = visibleChapteringCuePoints
        for cell in chapteringCollectionView.visibleCells {
            guard let indexPath = chapteringCollectionView.indexPath(for: cell),
                  let chapterCell = cell as? ChapteringCuePointCell,
                  cuePoints.indices.contains(indexPath.item) else { continue }
            let cuePoint = cuePoints[indexPath.item]
            chapterCell.configure(
                label: cuePoint.label,
                tagText: cuePoint.tagText,
                formattedTime: chapteringRelativeOffset(for: cuePoint).getTimeInString(),
                thumbnail: cuePoint.thumbnail,
                expanded: true
            )
        }
    }

    // MARK: - UICollectionViewDataSource / Delegate

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Show one empty-state cell when there are no cue points yet.
        max(visibleChapteringCuePoints.count, 1)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cuePoints = visibleChapteringCuePoints
        guard !cuePoints.isEmpty else {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: ChapteringEmptyStateCell.reuseIdentifier,
                for: indexPath
            )
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ChapteringCuePointCell.reuseIdentifier,
            for: indexPath
        ) as! ChapteringCuePointCell
        let cuePoint = cuePoints[indexPath.item]
        cell.configure(
            label: cuePoint.label,
            tagText: cuePoint.tagText,
            formattedTime: chapteringRelativeOffset(for: cuePoint).getTimeInString(),
            thumbnail: cuePoint.thumbnail,
            expanded: true
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cuePoints = visibleChapteringCuePoints
        guard cuePoints.indices.contains(indexPath.item) else { return }
        delegate?.seekTo(seconds: chapteringRelativeOffset(for: cuePoints[indexPath.item]))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
        let height = (flowLayout?.itemSize.height ?? 291) > 0 ? (flowLayout?.itemSize.height ?? 291) : 291
        guard !visibleChapteringCuePoints.isEmpty else {
            let insets = flowLayout?.sectionInset ?? .zero
            return CGSize(
                width: max(collectionView.bounds.width - insets.left - insets.right, 0),
                height: height
            )
        }
        if let flowLayout, flowLayout.itemSize != .zero {
            return flowLayout.itemSize
        }
        return CGSize(width: 380, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        let focusedInCollection = context.nextFocusedView?.isDescendant(of: collectionView) ?? false
        setChapteringCollectionExpanded(focusedInCollection)

        coordinator.addCoordinatedFocusingAnimations { _ in
            (context.nextFocusedView as? ChapteringCuePointCell)?.setFocusedAppearance(true)
            (context.previouslyFocusedView as? ChapteringCuePointCell)?.setFocusedAppearance(false)
            (context.nextFocusedView as? ChapteringEmptyStateCell)?.setFocusedAppearance(true)
            (context.previouslyFocusedView as? ChapteringEmptyStateCell)?.setFocusedAppearance(false)

            let cuePoints = self.visibleChapteringCuePoints
            let focusedIndex = (context.nextFocusedView as? UICollectionViewCell)
                .flatMap { collectionView.indexPath(for: $0)?.item }
            self.sliderView.setFocusedCuePoint(at: focusedIndex.flatMap { cuePoints.indices.contains($0) ? $0 : nil })
        }
    }
}

// MARK: - Cue point date / tag helpers

extension ChapteringCuePoint {
    static let eventStartUtcFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let eventStartUtcFractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Absolute air time of the chapter, derived from the ISO-8601 `event_start_utc`
    /// broadcast start plus the chapter's `startTime` offset (in seconds).
    var eventStartDate: Date? {
        guard let eventStartUtc, !eventStartUtc.isEmpty else { return nil }
        let eventStart = ChapteringCuePoint.eventStartUtcFormatter.date(from: eventStartUtc)
            ?? ChapteringCuePoint.eventStartUtcFractionalFormatter.date(from: eventStartUtc)
        return eventStart?.addingTimeInterval(startTime)
    }

    /// Tag displayed on a cue-point card (the associated stock symbols).
    var tagText: String? {
        guard let stocks, !stocks.isEmpty else { return nil }
        return stocks
    }
}

// MARK: - Empty state cell

/// Shown in the chapter collection when chaptering is enabled but there are no cue
/// points available yet.
final class ChapteringEmptyStateCell: UICollectionViewCell {
    static let reuseIdentifier = "ChapteringEmptyStateCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Live Recaps"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        return label
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.text = "Live Recaps not available yet."
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Check back later when live recaps are available."
        label.textColor = UIColor.white.withAlphaComponent(0.9)
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(titleLabel)
        contentView.addSubview(cardView)
        cardView.addSubview(headlineLabel)
        cardView.addSubview(messageLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFocused: Bool { true }

    func setFocusedAppearance(_ focused: Bool) {
        cardView.backgroundColor = UIColor.white.withAlphaComponent(focused ? 0.20 : 0.10)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let horizontalPadding: CGFloat = 14
        let availableWidth = max(contentView.bounds.width - (horizontalPadding * 2), 0)
        titleLabel.frame = CGRect(x: horizontalPadding, y: 10, width: availableWidth, height: 30)
        cardView.frame = CGRect(x: horizontalPadding, y: titleLabel.frame.maxY + 16, width: availableWidth, height: 92)
        headlineLabel.frame = CGRect(x: 24, y: 18, width: max(cardView.bounds.width - 48, 0), height: 24)
        messageLabel.frame = CGRect(x: 24, y: 48, width: max(cardView.bounds.width - 48, 0), height: 34)
    }
}
