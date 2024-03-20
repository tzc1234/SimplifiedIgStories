//
//  PreviewStoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/03/2024.
//

import SwiftUI
import Combine

extension StoryView {
    static func preview(story: Story, parentViewModel: StoriesViewModel) -> StoryView {
        let storiesViewModel = StoriesViewModel.preview
        let animationHandler = StoryAnimationHandler.preview(story: story, currentStoryHandler: storiesViewModel)
        let storyViewModel = StoryViewModel(storyId: story.id, fileManager: DummyFileManager())
        
        return StoryView(
            story: story,
            shouldCubicRotation: false,
            storyViewModel: storyViewModel,
            animationHandler: animationHandler, 
            portionMutationHandler: StoriesViewModel.preview,
            getProgressBar: {
                ProgressBar(story: story, currentStoryId: story.id, animationHandler: animationHandler)
            },
            onDisappear: { _ in }
        )
    }
}

extension StoryAnimationHandler {
    static func preview(story: Story, currentStoryHandler: CurrentStoryHandler) -> StoryAnimationHandler {
        StoryAnimationHandler(
            storyId: story.id,
            currentStoryHandler: currentStoryHandler,
            animationShouldPausePublisher: Empty<Bool, Never>().eraseToAnyPublisher()
        )
    }
}
