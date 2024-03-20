//
//  PreviewStoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/03/2024.
//

import SwiftUI
import Combine

extension StoryView {
    static let preview: StoryView = {
        let story = PreviewData.stories[0]
        let storiesViewModel = StoriesViewModel.preview
        let animationHandler = StoryAnimationHandler.preview
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
    }()
}

extension StoryAnimationHandler {
    static let preview: StoryAnimationHandler = StoryAnimationHandler(
        storyId: PreviewData.stories[0].id,
        currentStoryHandler: StoriesAnimationHandler.preview,
        animationShouldPausePublisher: Empty<Bool, Never>().eraseToAnyPublisher()
    )
}

extension StoriesAnimationHandler {
    static let preview: StoriesAnimationHandler = StoriesAnimationHandler(getStories: { PreviewData.stories })
}
