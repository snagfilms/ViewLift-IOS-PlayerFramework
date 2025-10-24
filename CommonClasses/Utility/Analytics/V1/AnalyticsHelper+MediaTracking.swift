//
//  AnalyticsHelper.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 26/09/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLAnalyticsLib
import VLPlayerLib
import AVKit
import Foundation
#if os(iOS)
import VLAuthenticationFramework
#else
import VLAuthenticationFramework_tvOS
#endif

struct ChapterInfoModel {
    var havingPreRollAds: Bool  = false
    var startTime: Double  = 0.0
    var endTime: Double  = 0.0
    
    init(havingPreRollAds: Bool, startTime: Double, endTime: Double) {
        self.havingPreRollAds = havingPreRollAds
        self.startTime = startTime
        self.endTime = endTime
    }
}

final class AnalyticsHelper: NSObject, PlayerVideoAnalyticsTrackDelegate {
    // MARK: Singleton
    static let shared = AnalyticsHelper()

    let reachability = NetworkReachability()
    
    let domain = "https://spinco.staging.web.viewlift.com"
    let orgid = "8CF467C25245AE3F0A490D4C@AdobeOrg"
    let resourceID = "sparkmedia"
    var requestorId = "sparkmedia"
    
    private override init() {
        super.init()
        let user = UserManager.shared.userIdentity
        self.setUserIdentity(userIdentity: user)
        
        VLAuthentication.sharedInstance.analyticsDelegate = self
    }

    // MARK: Session State
    private var contentInfo: VLContentInfo? = nil
    private var currentAdAssetInfo: VLAdAssetInfo?
    private var userIdentity: VLUserIdentity?
    private var isFullScreen: Bool = false

    // MARK: Event options
    struct TrackOptions: OptionSet {
        let rawValue: Int
        static let content    = TrackOptions(rawValue: 1 << 0)
        static let ads        = TrackOptions(rawValue: 1 << 1)
        static let tvProvider = TrackOptions(rawValue: 1 << 2)
        static let all: TrackOptions = [.content, .ads, .tvProvider]
    }
}

// MARK: - Session APIs
extension AnalyticsHelper {
    func setUserIdentity(userIdentity: VLUserIdentity?) {
        self.userIdentity = userIdentity
    }

    func setPlayerScreen(isFullScreen: Bool = false) {
        self.isFullScreen = isFullScreen
    }

    func setAdsAssets(adInfo: VLAdAssetInfo?) {
        self.currentAdAssetInfo = adInfo
    }
    
    func setVideoAssets(contentInfo: VLContentInfo) {
        self.contentInfo = contentInfo
    }

    func resetSession() {
        contentInfo = nil
        currentAdAssetInfo = nil
        userIdentity = nil
        requestorId = ""
        isFullScreen = false
    }
    
//    func triggerVideoSessionStartEvent(contentInfo: VLContentInfo, chapterInfo: ChapterInfoModel){
//        self.setVideoAssets(contentInfo: contentInfo)
//        
//        self.playerDidLoadVideo()
//        
//        self.playerDidStartPlaying()
//        
//        if !chapterInfo.havingPreRollAds && chapterInfo.endTime > chapterInfo.startTime {
//            let startTime = chapterInfo.startTime
//            let endTime = chapterInfo.endTime
//            
//            self.playerChapterDidStart(
//                currentTime: startTime,
//                endTime: endTime
//            )
//        }
//    }
}

// MARK: - Playback lifecycle + media load
extension AnalyticsHelper {
    func playerDidStartPlaying() { track(.playStarted) } //done

    func playerDidPaused() { track(.videoPauseStarted) } //done

    func playerSessionEnded() {
        self.track(.trackSessionEnd) //done
        
        self.resetSession()
    }

    func trackVideoCompletedAnalytics() {
        self.playerChapterDidComplete()
        
        track(.videoComplete)
        
        
    }

    func playerDidLoadVideo() {
        track(.mediaPlay, options: .all)
    }
}

// MARK: - Ads
extension AnalyticsHelper {
    func trackAdDidStartsAnalytics() {
        track(.adsStart, options: .ads)
    }
    
    func trackAdDidCompleteAnalytics() {
        track(.adsComplete, options: .ads)
    }
    
    func trackAdBreakStartAnalytics() {
        self.playerChapterDidComplete()
        
        track(.adsBreakStart, options: .ads)
    }
    
    func trackAdBreakCompleteAnalytics(playerCurrentTime: Double, chapterEnd: Double) {
        track(.adsBreakComplete, options: .ads)
        
        self.playerChapterDidStart(currentTime: playerCurrentTime, endTime: chapterEnd)
    }
}

// MARK: - Buffering / Bitrate
extension AnalyticsHelper {
    func playerDidStartBuffering() {
        track(.videoBuffer)
    }

    func playerDidBufferingComplete() {
        track(.videoBufferComplete)
    }

    func playerDidBitRateChange() {
        track(.playerBitrateChanged)
    }
}

// MARK: - Seeking
extension AnalyticsHelper {
    func playerSeekDidStart() {
        track(.videoSeekStarted)
    }

    func playerSeekDidComplete() {
        track(.videoSeekCompleted)
    }
}

// MARK: - Chapters
extension AnalyticsHelper {
    func playerChapterDidStart(currentTime: Double, endTime: Double) {
        track(.videochapterStart(currentTime, endTime), options: [.content])
    }

    func playerChapterDidComplete() {
        track(.videoChapterComplete)
    }
}

// MARK: - Playhead updates
extension AnalyticsHelper {
    func updatePlayhead(time: Double) {
        track(.updateCurrentPlayHead(time), options: [])
    }
}

// MARK: - Errors
extension AnalyticsHelper {
    func playerDidFail(errorMessage: String, isFatal: Bool) {
        track(.errorEvent, options: []) {
            $0.errorMessage(errorMessage)
        }
    }

    func trackVideoFailErrorAnalytics(errorMessage: String) {
        track(.errorEvent, options: []) {
            $0.errorMessage(errorMessage)
        }
    }
}

// MARK: - Language / frames hooks
extension AnalyticsHelper {
    func playerDidChangeClosedCaptionLanguage(language: String?) {}
    func playerDidChangeAudioLanguage(language: String?) {}
    func playerDidDropFrames(count: Int) {}
    func playerFirstFrameLoaded() {}
}

// MARK: - Parsing
extension AnalyticsHelper {
    @discardableResult
    func parseVLVideoResponse(from dictionary: [String: Any]) -> VLVideoResponseModel? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            let response = try Self.decoder.decode(VLVideoResponseModel.self, from: jsonData)
            return response
        } catch {
            print("❌ Failed to decode from dictionary:", error)
            return nil
        }
    }
    
    func getFormattedDateFromTimestamp(timestamp: TimeInterval?) -> String? {
        guard let timestamp = timestamp else {
            return nil
        }
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.timeZone = .current
        let formattedDate = formatter.string(from: date)
        print("Publish Date: \(formattedDate)")
        return formattedDate
    }
}

// MARK: - Tracking core
private extension AnalyticsHelper {
    func track(_ event: VLAnalyticsEvent,
               options: TrackOptions = .all,
               configure: ((VLEventModelBuilder) -> VLEventModelBuilder)? = nil) {
        var builder = baseBuilder(event: event, options: options)
        if let configure = configure {
            builder = configure(builder)
        }
        VLAnalytics.shared.trackEvent(data: builder.build())
    }
}

// MARK: - Builders
private extension AnalyticsHelper {
    func baseBuilder(event: VLAnalyticsEvent,
                     options: TrackOptions) -> VLEventModelBuilder {
        var builder = VLEventModelBuilder().eventType(event)
        if options
            .contains(.content) {
            builder = builder.contentInfo( self.contentInfo )
        }
        if options.contains(.ads) {
            builder = builder.adsInfo(currentAdAssetInfo)
        }
        
        if options.contains(.tvProvider) {
            builder = builder.tvProviderInfo(getTVEProviderInfo())
        }
        
        return builder
    }

}

// MARK: - Utilities
private extension AnalyticsHelper {
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .useDefaultKeys
        return d
    }()

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy"
        f.timeZone = .current
        return f
    }()

    static func dateMMDDYYYY(from timestamp: TimeInterval?) -> String? {
        guard let ts = timestamp else { return nil }
        return dateFormatter.string(from: Date(timeIntervalSince1970: ts))
    }
}
