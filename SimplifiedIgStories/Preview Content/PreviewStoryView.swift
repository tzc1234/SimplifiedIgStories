//
//  PreviewStoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/03/2024.
//

import SwiftUI

extension StoryView {
    static func preview(storyId: Int, parentViewModel: StoriesViewModel) -> StoryView {
        StoryView(
            storyId: storyId,
            storyViewModel: StoryViewModel(
                storyId: storyId,
                parentViewModel: parentViewModel,
                fileManager: DummyFileManager(),
                mediaSaver: DummyMediaSaver()
            )
        )
    }
}
