//
//  PreviewStoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/03/2024.
//

import SwiftUI

extension StoryView {
    static func preview(story: Story, parentViewModel: StoriesViewModel) -> StoryView {
        StoryView(
            story: story,
            storyViewModel: StoryViewModel(
                storyId: story.id,
                parentViewModel: parentViewModel,
                fileManager: DummyFileManager(),
                mediaSaver: DummyMediaSaver()
            )
        )
    }
}
