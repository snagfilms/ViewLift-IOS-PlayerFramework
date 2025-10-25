////
////  PlayerViewController_iOS+Analytics.swift
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
extension PlayerViewController_iOS {
//    // Called when the player starts playback
    func getAdsInfo() -> VLAdAssetInfo? {
        return self.currentAdAssetInfo
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
    /// - Units: Seconds (exclude SSAI ad duration). You will get total ads duration with ServerSideAdTrackingDelegate: totalAdsDuration
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
        self.isFullscreen ? "FullScreen" : "Normal"
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
        1_758_888_531
    }

    /// Program end timestamp in milliseconds since Unix epoch for linear schedules.
    /// - Required (linear): Milliseconds as Int64/Double.
    /// - Units: Milliseconds (ms).
    var programEndTimeMiliSeconds: Double {
        1_758_889_990
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
    
    func getVideoInfoV2() -> VLContentInfoAnalytics? {
        return VLContentInfoAnalytics(
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
            programStartTimeMiliSeconds: programStartTimeMiliSeconds,
            programEndTimeMiliSeconds: programEndTimeMiliSeconds
        )
        
    }
}
