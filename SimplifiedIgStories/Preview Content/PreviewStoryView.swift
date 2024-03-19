//
//  PreviewStoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/03/2024.
//

import SwiftUI

extension StoryView {
    static func preview(story: Story, parentViewModel: StoriesViewModel) -> StoryView {
        let storyViewModel = StoryViewModel(
            storyId: story.id,
            parentViewModel: parentViewModel,
            fileManager: DummyFileManager(),
            mediaSaver: DummyMediaSaver()
        )
        
        return StoryView(
            story: story,
            shouldCubicRotation: false,
            storyViewModel: storyViewModel,
            getProgressBar: {
                ProgressBar(story: story, currentStoryId: story.id, storyViewModel: storyViewModel)
            },
            onDisappear: { _ in }
        )
    }
}
