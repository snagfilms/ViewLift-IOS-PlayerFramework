//
//  VideoPlayerViewModel.swift
//  playerKinUI
//
//  Created by Japneet Singh on 02/08/25.
//

import SwiftUI
import AVFoundation
import VLPlayerLib

// MARK: Player Control Type
enum PlayerControlsLayoutType {
    case streamControls
    case liveControls
    case dvrControls
}

// MARK: PlayerControlsView Delegate
protocol PlayerControlsViewDelegate: AnyObject {
    func playPauseTapped(isPlaying: Bool)
    func muteTapped(isMuted: Bool)
    func slowMotionTapped(isSlowMotion: Bool)
    func controlsLockTapped(isLocked: Bool)
    func subtitleTapped(isEnabled: Bool)
    func piPTapped()
    func castingTapped(button: UIButton)
    func airPlayTapped()
    func fullScreenTapped(isFullScreen: Bool)
    func rewindTapped()
    func forwardTapped()
    func settingsTapped()
    func seekToLive()
    func sliderBeginTracking(time: TimeInterval)
    func sliderChangedTracking(time: TimeInterval)
    func sliderEndedTracking(time: TimeInterval)
    func setupPictureInPicture()
    func volumeChange(sliderValue: Float)
}

struct PlayerControlsConfig {
    var isChromeCastSupported: Bool
    var isAirPlaySupported: Bool
    var isPIPSupported: Bool
    var isSettingsSupported: Bool
    var isSlowMoSupported: Bool
    var isSubTitleSupported: Bool
    var isVideoLiveStream: Bool
    var isDVREnabled: Bool
    var videoTitle: String
    var playerControlsColor: PlayerControlsColor?
    
    init(isChromeCastSupported: Bool = true,
         isAirPlaySupported: Bool = true,
         isPIPSupported: Bool = true,
         isSettingsSupported: Bool = true,
         isSubTitleSupported: Bool = true,
         isSlowMoSupported: Bool = true,
         isVideoLiveStream: Bool = false,
         isDVREnabled: Bool = false,
         videoTitle: String = "",
         playerControlsColor: PlayerControlsColor? = nil) {
        self.isChromeCastSupported = isChromeCastSupported
        self.isAirPlaySupported = isAirPlaySupported
        self.isPIPSupported = isPIPSupported
        self.isSettingsSupported = isSettingsSupported
        self.isSubTitleSupported = isSubTitleSupported
        self.isSlowMoSupported = isSlowMoSupported
        self.isVideoLiveStream = isVideoLiveStream
        self.isDVREnabled = isDVREnabled
        self.videoTitle = videoTitle
        self.playerControlsColor = playerControlsColor
    }
}

// MARK: - Player ViewModel
class PlayerControlsViewModel: ObservableObject {
    @Published var playerState = PlayerState()
    @Published var isLandscape: Bool = false
    @Published var isSliderDragging: Bool = false
    @Published var adRunningOnPlayer: Bool = false
    var playerControlsConfig: PlayerControlsConfig
    
    weak internal var delegate: PlayerControlsViewDelegate?
    @Published var playerControlsType: PlayerControlsLayoutType = .streamControls
    
    private var sentSliderBeginTracking: Bool = false
    
    internal var volumeObserver: NSKeyValueObservation?
    internal let audioSession = AVAudioSession.sharedInstance()
    
    private var seekBarFrame: CGRect = .zero
    private var playerFrame: CGRect = .zero
    
    @Published var adsCuePoints: [Double] = []
    @Published var adsDuration: TimeInterval = .zero

    @Published var chapterCuePoints: [Double] = []
    @Published var chapterDuration: TimeInterval = .zero
    @Published var chapterCueConfig: VLPlayer.ChapterCueConfig = VLPlayer.ChapterCueConfig()
    @Published var activeChapterDragTitle: String?
    /// Pre-computed display segments used for the drag-preview bubble.
    private var chapterDisplaySegments: [ChapterDisplaySegment] = []

    var isAdOnMainView: Bool = false
    var adRunningOnInternalPlayer: Bool = false
    var initiallyMuted: Bool
    init(delegate: PlayerControlsViewDelegate,
         playerControlsConfig: PlayerControlsConfig, initiallyMuted: Bool = false) {
        self.initiallyMuted = initiallyMuted
        self.delegate = delegate
        self.playerControlsConfig = playerControlsConfig
        
        if playerControlsConfig.isVideoLiveStream == true {
            if playerControlsConfig.isDVREnabled == true {
                playerControlsType = .dvrControls
                playerState.timeLabel = ""
                playerState.currentTime = 100
            } else {
                playerControlsType = .liveControls
            }
        } else {
            playerControlsType = .streamControls
        }
        self.playerState.isMuted = initiallyMuted
        startVolumeMonitoring()
//        if playerControlsConfig.isPIPSupported {
//            self.delegate?.setupPictureInPicture()
//        }
    }
    
    deinit{
        stopVolumeMonitoring()
    }
    
    func togglePlayPause() {
        if playerState.isPlaying {
            delegate?.playPauseTapped(isPlaying: false)
            playerState.isPlaying = false
        } else {
            delegate?.playPauseTapped(isPlaying: true)
            playerState.isPlaying = true
        }
    }
    
    func toggleMute() {
        if playerState.isMuted {
            delegate?.muteTapped(isMuted: false)
            playerState.isMuted = false
        } else {
            delegate?.muteTapped(isMuted: true)
            playerState.isMuted = true
        }
    }
    
    func toggleMute(isMuted: Bool) {
        if isMuted {
            delegate?.muteTapped(isMuted: false)
            playerState.isMuted = false
        } else {
            delegate?.muteTapped(isMuted: true)
            playerState.isMuted = true
        }
    }
    
    func toggleSlowMotion() {
        if playerState.isSlowMotion {
            delegate?.slowMotionTapped(isSlowMotion: false)
            playerState.isSlowMotion = false
        } else {
            delegate?.slowMotionTapped(isSlowMotion: true)
            playerState.isSlowMotion = true
        }
    }
    
    func toggleControlsLock() {
        if playerState.isControlsLocked {
            delegate?.controlsLockTapped(isLocked: false)
            playerState.isControlsLocked = false
        } else {
            delegate?.controlsLockTapped(isLocked: true)
            playerState.isControlsLocked = true
        }
    }
    
    func toggleSubtitle() {
        if playerState.subtitle {
            delegate?.subtitleTapped(isEnabled: false)
        } else {
            delegate?.subtitleTapped(isEnabled: true)
        }
    }
    
    func seekTo(time: TimeInterval) {
        playerState.currentTime = time * 100
    }
    
    func sliderTracking(time: TimeInterval) {
        
        if sentSliderBeginTracking == false {
            sentSliderBeginTracking = true
            delegate?.sliderBeginTracking(time: time / 100)
        } else {
            delegate?.sliderChangedTracking(time: time / 100)
        }
    }
    
    func sliderEndedTracking(time: TimeInterval) {
        delegate?.sliderEndedTracking(time: time / 100)
        sentSliderBeginTracking = false
    }
    
    func seekToLiveTapped() {
        delegate?.seekToLive()
    }
    
    func togglePiP() {
        delegate?.piPTapped()
        playerState.isPiP.toggle()
    }
    
    func castButtonTapped(sender: UIButton) {
        delegate?.castingTapped(button: sender)
    }
    
    func toggleAirPlay() {
        delegate?.airPlayTapped()
    }
    
    func toggleFullScreen(isFullScreen: Bool) {
        delegate?.fullScreenTapped(isFullScreen: isFullScreen)
    }
    
    func rewindTapped() {
        delegate?.rewindTapped()
    }
    
    func forwardTapped() {
        delegate?.forwardTapped()
    }
    
    func settingsTapped() {
        delegate?.settingsTapped()
    }
    
}

extension PlayerControlsViewModel {
    
    var getTitle: String {
        playerState.title
    }
    
    var getTimeLabel: String {
        playerState.timeLabel
    }
    
    var getLiveLabel: String {
        playerState.liveLabel
    }
    
    var getLiveButonColor: Color {
        playerState.liveLabel == "LIVE" ? .gray : .red
    }
    
    func getIconColor() -> Color {
        return Color(Utility.hexStringToUIColor(hex: playerControlsConfig.playerControlsColor?.iconColor ?? "#ffffff"))
    }
    
    func getCueIconColor() -> Color {
        return Color(Utility.hexStringToUIColor(hex: playerControlsConfig.playerControlsColor?.cueIconColor ?? "#ffffff"))
    }
    
    func getTextColor() -> Color {
        return Color(Utility.hexStringToUIColor(hex: playerControlsConfig.playerControlsColor?.textColor ?? "#ffffff"))
    }
    
    func getProgressBarColor() -> Color {
        return Color(Utility.hexStringToUIColor(hex: playerControlsConfig.playerControlsColor?.progressBarColor ?? "#ff0000"))
    }
    
    func getProgressBarBGColor() -> Color {
        return Color(Utility.hexStringToUIColor(hex: playerControlsConfig.playerControlsColor?.progressBarBGColor ?? "#999797"))
    }
    
    // Format seconds into HH:MM:SS
    func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, !seconds.isNaN else {
            return "00:00"
        }
        
        let clampedSeconds = max(0, Int(seconds.rounded()))
        let hours = clampedSeconds / 3600
        let minutes = (clampedSeconds % 3600) / 60
        let secs = clampedSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    func updateTimeLabel(totalTime: Double, currentTime: Double) {
        if playerControlsConfig.isDVREnabled {
            if totalTime > 3 {
                updateTimeLabel(text: "-\(formatTime(totalTime))")
                setLiveButtonText(text: "GO LIVE")
            } else {
                updateTimeLabel(text: "")
                setLiveButtonText(text: "LIVE")
            }
        } else {
            let displayString = "\(formatTime(currentTime)) / \(formatTime(totalTime))"
            updateTimeLabel(text: displayString)
        }
    }
    
    func updateSkin(title: String, isLive: Bool, isDVREnabled: Bool) {
        playerState.title = title
        playerControlsConfig.isVideoLiveStream = isLive
        playerControlsConfig.isDVREnabled = isDVREnabled
        
        if isLive {
            if isDVREnabled {
                playerControlsType = .dvrControls
                playerState.timeLabel = ""
                playerState.currentTime = 100
            } else {
                playerControlsType = .liveControls
            }
        } else {
            playerControlsType = .streamControls
        }
    }
    
    func setupPiP() {
        if playerControlsConfig.isPIPSupported {
            self.delegate?.setupPictureInPicture()
        }
    }
    
    func updateTimeLabel(text: String) {
        playerState.timeLabel = text
    }
    
    func updatePlayingState(isPlaying: Bool) {
        playerState.isPlaying = isPlaying
    }
    
    func updateCastingState(isCasting: Bool) {
        playerState.isCasting = isCasting
    }
    
    func updateMuteState(isMute: Bool) {
        playerState.isMuted = isMute
    }
    
    func updateSubtitleState(isEnabled: Bool) {
        playerState.subtitle = isEnabled
    }
    
    func hidePlayButtonOnBuffering() {
    }
    
    func showPlayButtonAfterBuffering() {
    }
    
    func closedCaptionButton(isHidden: Bool) {
        playerControlsConfig.isSubTitleSupported = !isHidden
    }
    
    func enableSettingButtonUserInteraction(isEnabled: Bool) {
    }
    
    func updateAdsStateOnPlayer(isRunning: Bool) {
        adRunningOnPlayer = isRunning
    }
    
    func showSkipIntro(showSkipButton: Bool) {
    }
    
    func setLiveButtonText(text: String) {
        playerState.liveLabel = text
    }
    
    func isAirPlayRouteActive(avPlayer:AVPlayer) -> Bool
    {
        if #available(iOS 13.0, *) {
            return avPlayer.isExternalPlaybackActive
        }
        return false
    }
    
    func setPipButtonSelected(isSelected: Bool) {
        playerState.isPiP = isSelected
    }
    
}


extension PlayerControlsViewModel {
    
    func handleFramesUpdate(_ values:  [String : CGRect]) {
        
        if let seekBarFrame = values["seekbar"],
           self.seekBarFrame != seekBarFrame {
            self.seekBarFrame = seekBarFrame
        }
        if let playerFrame = values["player"],
           self.playerFrame != playerFrame {
            self.playerFrame = playerFrame
        }
    }
    
    func getOriginBuffer() -> CGPoint {
        return CGPoint(
            x: seekBarFrame.origin.x,
            y: playerFrame.height - seekBarFrame.minY
        )
    }
    
}

// MARK: - Chapter Display Segment
/// Mirrors the SDK's internal `ChapterCueSegment`, carrying a resolved [startTime, endTime)
/// window for the drag-preview bubble.  The `endTime` is computed according to
/// `ChapterCueConfig.showChapterTitleTillCuePoint` just as the SDK does in
/// `resolvedChapterSegmentEndTime`.
private struct ChapterDisplaySegment {
    let startTime: Double
    let endTime: Double
    let label: String

    /// Returns `true` when `second` falls within this segment's [startTime, endTime) window.
    func contains(_ second: Double) -> Bool {
        second.isFinite && second >= startTime && second < endTime
    }
}

extension PlayerControlsViewModel {

    /// Updates chapter cue markers and drag-preview metadata on the custom seekbar.
    /// Called via the `chapterCuePointsUpdated` delegate when using `.custom` controls.
    ///
    /// Replicates the SDK's `buildChapterCueSegments` / `resolvedChapterSegmentEndTime` logic:
    /// - `showChapterTitleTillCuePoint = false` → title spans to the next chapter's startTime.
    /// - `showChapterTitleTillCuePoint = true`  → title spans `startTime + origLength`
    ///   (falls back to nextStartTime when origLength is zero / invalid).
    ///
    /// - Parameters:
    ///   - cuePoints: Chapter start-time positions (seconds) in the current playback window.
    ///   - duration: Playback window duration used to normalise positions.
    ///   - labels: Chapter titles aligned with `cuePoints` by index.
    ///   - origLengths: `ChapterSegment.origLength` values aligned with `cuePoints` by index.
    ///   - cueConfig: Visual and behavioural configuration for cue markers.
    func setChapterCuePoints(
        cuePoints: [Double],
        duration: TimeInterval,
        labels: [String] = [],
        origLengths: [Double] = [],
        cueConfig: VLPlayer.ChapterCueConfig = VLPlayer.ChapterCueConfig()
    ) {
        guard duration > 0 else {
            chapterCuePoints = []
            chapterDuration = .zero
            chapterDisplaySegments = []
            chapterCueConfig = cueConfig
            return
        }

        let filtered = cuePoints
            .filter { $0.isFinite && $0 >= 0 && $0 <= duration }
            .sorted()
        chapterCuePoints = filtered
        chapterDuration = duration
        chapterCueConfig = cueConfig

        chapterDisplaySegments = filtered.enumerated().map { index, cueTime in
            let label = index < labels.count ? labels[index] : ""
            let nextStartTime = (index + 1 < filtered.count) ? filtered[index + 1] : duration

            let endTime: Double
            if cueConfig.showChapterTitleTillCuePoint {
                let origLength = index < origLengths.count ? origLengths[index] : 0
                if origLength.isFinite && origLength > 0 {
                    // endTime = mappedStartTime + origLength, clamped to window — matches SDK.
                    endTime = min(cueTime + origLength, duration)
                } else {
                    endTime = nextStartTime
                }
            } else {
                endTime = nextStartTime
            }

            return ChapterDisplaySegment(startTime: cueTime, endTime: endTime, label: label)
        }
    }

    /// Updates the drag-preview bubble title to the chapter whose window contains `sliderValue`.
    /// Mirrors the SDK's `updateActiveChapterDragTitle` using the pre-computed `ChapterDisplaySegment`.
    /// - Parameter sliderValue: Normalised slider position in the range 0–100.
    func updateActiveChapterDragTitle(sliderValue: Double) {
        guard !chapterDisplaySegments.isEmpty, chapterDuration > 0 else {
            activeChapterDragTitle = nil
            return
        }
        let currentSecond = (sliderValue / 100.0) * chapterDuration
        if let segment = chapterDisplaySegments.first(where: { $0.contains(currentSecond) }),
           !segment.label.isEmpty {
            activeChapterDragTitle = segment.label
        } else {
            activeChapterDragTitle = nil
        }
    }

    func clearActiveChapterDragTitle() {
        activeChapterDragTitle = nil
    }

}

extension PlayerControlsViewModel {

    func setCuePointsFromPlayer(adModel adsModel: SSAIAdsModel?, duration: TimeInterval) {
        if let adsModel, let avails = adsModel.avails, avails.isEmpty == false {
            var adModelStarTime: [Double] = [Double]()
            for adModel in avails {
                if let adsDuration = adModel.adsDuration, adsDuration > 0, let adStartTime = adModel.startTimeDuration {
                    if adModel.adsDuration != nil, let adStartTime = adModel.startTimeDuration {
                        adModelStarTime.append(adStartTime)
                    }
                }
            }
            adsCuePoints = adModelStarTime
            adsDuration = duration
        }
    }
    
}
