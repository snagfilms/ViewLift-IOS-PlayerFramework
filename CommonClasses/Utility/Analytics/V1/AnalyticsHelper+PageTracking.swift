//
//  AnalyticsHelper+PageTracking.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 26/09/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import VLAnalyticsLib

extension AnalyticsHelper {
    
    func triggerAnalytics(event: VLAnalyticsEvent, pageInfo: VLPageInfo? = nil, userInfo: VLUserInfo? = nil) {
            let eventData = VLEventModelBuilder()
                .eventType(event)
                .pageInfo(pageInfo)
                .userInfo(userInfo)
                .build()
        self.handleTrackEvent(eventData: eventData)
    }
    
    func triggerSignoutAnalytics() {
            let eventData = VLEventModelBuilder()
            .eventType(.adobePassAuthenticateDeactivate)
            .build()
        self.handleTrackEvent(eventData: eventData)
    }
    
}
