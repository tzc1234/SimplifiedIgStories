//
//  AnalyticsHelper.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 27/04/2022.
//

import Firebase

class AnalyticsHelper {
    static func logStoryIconTapEvent(by storyId: Int?) {
        #if TEST
        if let storyId = storyId {
            Analytics.logEvent("tap_story_icon", parameters: ["storyId": storyId])
        }
        #endif
    }
}
