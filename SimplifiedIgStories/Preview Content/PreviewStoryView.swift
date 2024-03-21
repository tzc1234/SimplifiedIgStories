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
        let storyViewModel = StoryViewModel(story: story)
        
        return StoryView(
            story: story,
            animationHandler: animationHandler,
            getStoryPortionView: { portion in
                StoryPortionView(
                    portion: portion,
                    storyViewModel: storyViewModel,
                    animationHandler: animationHandler,
                    portionMutationHandler: StoriesViewModel.preview
                )
            },
            onDisappear: { _ in }
        )
    }()
}

extension StoryAnimationHandler {
    static let preview: StoryAnimationHandler = StoryAnimationHandler(
        storyId: PreviewData.stories[0].id,
        currentStoryAnimationHandler: StoriesAnimationHandler.preview,
        animationShouldPausePublisher: Empty<Bool, Never>().eraseToAnyPublisher()
    )
}

extension StoriesAnimationHandler {
    static let preview: StoriesAnimationHandler = StoriesAnimationHandler(
        storiesPublisher: CurrentValueSubject(PreviewData.stories).eraseToAnyPublisher()
    )
}
