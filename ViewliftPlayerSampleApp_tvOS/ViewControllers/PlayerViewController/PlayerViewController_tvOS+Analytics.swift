////
////  PlayerViewController_tvOS+Analytics.swift
////  ViewliftPlayerSampleApp
////
////  Created by vikassachan@viewlift.com on 12/08/25.
////  Copyright © 2025 Viewlift. All rights reserved.
////
//
import VLAnalyticsLib
import VLPlayerLib
import AVKit
//
//// Handles analytics integration for player events and content/ad info
extension PlayerViewController_tvOS {
//    
//    // Returns current ad asset info for analytics
    func getAdsInfo() -> VLAdAssetInfo? {
        return self.currentAdAssetInfo
    }
//    
//    // Parses video response dictionary and decodes to model
    func parseVLVideoResponse(from dictionary: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            let response = try decoder.decode(VLVideoResponseModel.self, from: jsonData)
            self.videoResponse = response
        } catch {
            print("❌ Failed to decode from dictionary:", error)
        }
    }
//    
//    // Formats a timestamp into a date string
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

    var video: VLVideo? {
        self.videoResponse?.video
    }
    
    /// Unique content identifier from the CMS or backend. 
    /// - Required: Must be a non-empty unique ID. 
    /// - Example: "EP024874280384". 
    var programId: String {
        video?.id ?? ""
    }

    /// Human-readable title of the content. 
    /// - Required: Provide the exact display title. 
    /// - Example: "India vs Australia Highlights". 
    var programTitle: String {
        video?.title ?? ""
    }

    /// Series identifier if the content belongs to a series; otherwise use "N/A" or make this optional. 
    /// - Required (series only): Provide the canonical series ID. 
    /// - Example: "SR00012345" or "N/A". 
    var seriesId: String {
        "N/A"
    }

    /// Series title if the content belongs to a series; otherwise use nil or "N/A" consistently. 
    /// - Required (series only): Provide the exact series title. 
    /// - Example: "MasterChef India" or nil. 
    var seriesTitle: String {
        "N/A"
    }

    /// Content type classification. 
    /// - Expected values: "linear", "video", "live". 
    /// - Note: Align with downstream analytics schema. 
    var contentType: String {
        "video"
    }

    /// Total playable duration of the content in seconds, excluding ad time. 
    /// - Required: Must be greater than 0 for VOD and linear; for live use 86400 (24 hours) unless specified otherwise. 
    /// - Units: Seconds (exclude SSAI ad duration). 
    var durationInSeconds: Int {
        86400
    }

    /// Air or publish date in "MM/dd/yyyy" format. 
    /// - VOD: Use the content publish date. 
    /// - Linear/Live: Use the program or event start date. 
    /// - Format: MM/dd/yyyy (e.g., 09/23/2025). 
    var airDate: String {
        "09/23/2025"
    }

    /// BCP‑47 language code for the primary content language. 
    /// - Examples: "en", "hi". 
    var language: String {
        "en"
    }

    /// Season number if the content belongs to a series season; otherwise nil. 
    /// - Required (series season only): Positive integer season index. 
    var seasonNumber: Int? {
        nil
    }
    
    /// Episode number if the content belongs to a series season's episode; otherwise nil.
    /// - Required (series season episode only): Positive integer season index.
    var episodeNumber: Int? {
        nil
    }

    /// Initial playback offset in seconds. 
    /// - Required: Use 0.0 when starting from the beginning; otherwise pass resume offset. 
    /// - Units: Seconds (Double). 
    var totalSecondsConsumed: Double? {
        0.0
    }

    /// Stream type for the playback context.
    /// - Expected values: "fullEpisodePlayer" (episodes), "vod" (non‑episodic VOD), "live" (live stream).
    var streamType: String {
        // If live, report "live"; otherwise default to "vod". Adjust to "fullEpisodePlayer" when the episode context is known.
        isLive ? "live" : "vod"
    }

    /// Primary content category.
    /// - Example: "Sports".
    var category: String {
        "Sports"
    }

    /// Content subcategory or "N/A" if not applicable.
    var subcategory: String {
        "N/A"
    }

    /// Player screen size at playback start.
    /// - Expected values: "FullScreen", "Normal".
    var screenSize: String {
        isFullScreen ? "FullScreen" : "Normal"
    }

    /// Monetization status of the content.
    /// - Expected values: "free", "premium".
    var videostatus: String {
        guard let data = videoResponse?.video else { return "free" }
        let isContentFree = data.monetizationModels?.contains(where: { $0.type == "FREE" }) ?? false
        let hasPlans = !(videoResponse?.plans?.isEmpty ?? true)
        return (hasPlans && isContentFree) ? "free" : "premium"
    }

    /// Streaming domain or URL host for the video stream, if required by the analytics pipeline.
    /// - Example: "stream.examplecdn.com".
    var videodomain: String {
        "" // Populate from the active playback URL host if available.
    }

    /// TMS/asset identifier used by downstream systems.
    /// - Example: "EP024874280384".
    var videotmsid: String {
        videoResponse?.video?.id ?? "EP024874280384"
    }

    /// Broadcast mode of the content.
    /// - Expected values: "Broadcast" (live/linear), "Digital" (VOD).
    var videobroadcast: String {
        isLive ? "Broadcast" : "Digital"
    }

    /// Short clip type if applicable; otherwise "N/A".
    var videocliptype: String {
        "N/A"
    }

    /// Content network or brand label.
    /// - Example: "cnbc".
    var videoNetwork: String {
        "cnbc"
    }

    /// How playback was initiated.
    /// - Expected values: "auto" (autoplay, up‑next, continuous play) or "manual" (explicit user action).
    /// - Default: "manual"
    /// - Notes: Use consistent casing as required by the analytics schema.
    var videoInitiateRaw: String {
        "manual" // Map from real initiation context if available.
    }

    /// Indicates whether the content is live at playback time.
    /// - Required: true for live/linear streams, false for VOD.
    var isLive: Bool {
        videoResponse?.video?.streamingInfo?.isLiveStream ?? false
    }

    /// Subtitle or episode subheading if available; otherwise "N/A".
    var subTitle: String {
        "N/A"
    }

    /// Asset identifier for linear channel programs.
    /// - Example: "EP024874280384".
    var assetId: String {
        videoResponse?.video?.id ?? "EP024874280384"
    }

    /// Program start timestamp in milliseconds since Unix epoch for linear schedules.
    /// - Required (linear): Milliseconds as Int64/Double.
    /// - Units: Milliseconds (ms).
    var programStartTimeMiliSeconds: Double {
        1_758_888_531 // Replace with schedule-derived ms timestamp when available.
    }

    /// Program end timestamp in milliseconds since Unix epoch for linear schedules.
    /// - Required (linear): Milliseconds as Int64/Double.
    /// - Units: Milliseconds (ms).
    var programEndTimeMiliSeconds: Double {
        1_758_889_990 // Replace with schedule-derived ms timestamp when available.
    }

    
    
//    // Builds and returns video content info for analytics
    func getVideoInfo() -> VLContentInfo? {
        return VLContentInfo(
            id: programId,
            title: programTitle,
            seriesId: seriesId,
            seriesTitle: seriesTitle,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            contentType: contentType,
            durationInSeconds: durationInSeconds,
            airDate: airDate,
            language: language,
            totalSecondsConsumed: totalSecondsConsumed,
            streamType: streamType,
            subcategory1: category,
            subcategory2: subcategory,
            screenSize: screenSize,
            videostatus: videostatus,
            videodomain: videodomain,
            videotmsid: videotmsid,
            videobroadcast: videobroadcast,
            videoInitiate: videoInitiateRaw,
            videocliptype: videocliptype,
            videonetwork: videoNetwork,
            isLive: isLive,
            subTitle: subTitle,
            assetId: assetId,
            programStartTimeMiliSeconds: programStartTimeMiliSeconds,
            programEndTimeMiliSeconds: programEndTimeMiliSeconds
        )
        
    }
//    
//    // Tracks the start of video playback for analytics
//    func trackVideoStart() {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.mediaPlay)
//            .contentInfo(getVideoInfo())
//            .tvProviderInfo(VLTVProviderInfo(tvProviderName: UserManager.shared.userIdentity?.mvpdProvider,
//                                             requestorId:/*requestorId*/ "")
//            )
//            .adsInfo(getAdsInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func trackAdDidStartsAnalytics() {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.adsStart)
//            .adsInfo(getAdsInfo())
//            .contentInfo(getVideoInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//   
//    func trackAdDidCompleteAnalytics() {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.adsComplete)
//            .adsInfo(getAdsInfo())
//            .contentInfo(getVideoInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    
//    func trackAdBreakStartAnalytics() {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.adsBreakStart)
//            .adsInfo(getAdsInfo())
//            .contentInfo(getVideoInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func trackAdBreakCompleteAnalytics() {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.adsBreakComplete)
//            .adsInfo(getAdsInfo())
//            .contentInfo(getVideoInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func playerDidStartPlaying() {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.playStarted)
//            .contentInfo(getVideoInfo())
//            .adsInfo(getAdsInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func playerDidPaused() {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.videoPauseStarted)
//            .contentInfo(getVideoInfo())
//            .adsInfo(getAdsInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
}
//
//extension PlayerViewController_tvOS: PlayerVideoAnalyticsTrackDelegate{
//    func playerSeekDidStart() {
//        
//    }
//    
//    func playerSeekDidComplete(newTime: Double, shouldResume: Bool) {
//        
//    }
//    
//    func playerChapterDidStart(currentTime: Double, endTime: Double) {
//        
//    }
//    
//    func playerDidFail(errorMessage: String, isFatal: Bool) {
//        
//    }
//    
//    func playerDidBufferingComplete() {
//        
//    }
//    
//    func playerDidLoadVideo() {
//        
//    }
//    
//    func playerDidChangeClosedCaptionLanguage(language: String?) {
//        
//    }
//    
//    func updatePlayhead(time: Double) {
//        
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.updateCurrentPlayHead(time))
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func playerDidLoadVideo(player: AVPlayer?) {
//        let loggedUser = UserManager.shared.userIdentity
//        
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.mediaPlay)
//            .contentInfo(getVideoInfo())
//            .tvProviderInfo(VLTVProviderInfo(tvProviderName: loggedUser?.mvpdProvider ?? "", requestorId: /* AppConfiguration.shared.tveSettings?.requestorId*/ "")
//            )
//            .adsInfo(getAdsInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    
//    func playerSeekDidStart(fromTimeInterval: Double) {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.videoSeekStarted)
//            .contentInfo(getVideoInfo())
//            .adsInfo(getAdsInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func playerSeekDidComplete(toTimeInterval: Double) {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.videoSeekCompleted)
//            .contentInfo(getVideoInfo())
//            .adsInfo(getAdsInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func playerSessionEnded() {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.trackSessionEnd)
//            .contentInfo(getVideoInfo())
//            .adsInfo(getAdsInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func trackVideoCompletedAnalytics() {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.videoComplete)
//            .contentInfo(getVideoInfo())
//            .adsInfo(getAdsInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func playerFirstFrameLoaded() {
//        debugPrint("")
//    }
//    
//    func trackVideoFailErrorAnalytics(errorMessage: String) {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.errorEvent)
//            .errorMessage(errorMessage)
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func playerDidChangeAudioLanguage(language: String?) {
//        
//    }
//    
//    func playerDidDropFrames(count: Int) {
//        
//    }
//    
//    func playerChapterDidStart(currentTime: Double) {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.videochapterStart(currentTime, 5.0))
//            .contentInfo(getVideoInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func playerChapterDidComplete() {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.videoChapterComplete)
//            .adsInfo(getAdsInfo())
//            .contentInfo(getVideoInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func playerDidBitRateChange() {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.playerBitrateChanged)
//            .adsInfo(getAdsInfo())
//            .contentInfo(getVideoInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//    func playerDidStartBuffering() {
//        let eventBuilder = VLEventModelBuilder()
//            .eventType(.videoBuffer)
//            .adsInfo(getAdsInfo())
//            .contentInfo(getVideoInfo())
//            .build()
//        VLAnalytics.shared.trackEvent(data: eventBuilder)
//    }
//    
//}
