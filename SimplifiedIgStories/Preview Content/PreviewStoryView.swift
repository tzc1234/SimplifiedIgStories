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
        let animationHandler = StoryAnimationHandler.preview(story: story)
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
    static func preview(story: Story) -> StoryAnimationHandler {
        StoryAnimationHandler(
            isAtFirstStory: { false },
            isAtLastStory: { false },
            isCurrentStory: { false },
            moveToPreviousStory: {},
            moveToNextStory: {},
            portions: { story.portions },
            isSameStoryAfterDragging: { false },
            isDraggingPublisher: Empty<Bool, Never>().eraseToAnyPublisher(), 
            animationShouldPausePublisher: Empty<Bool, Never>().eraseToAnyPublisher()
        )
    }
}