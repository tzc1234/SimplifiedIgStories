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
        let storyPortionViewModel = StoryPortionViewModel(
            story: story,
            portion: story.portions[0],
            fileManager: DummyFileManager(),
            mediaSaver: DummyMediaSaver()
        )
        
        return StoryView(
            story: story,
            animationHandler: animationHandler,
            getStoryPortionView: { portion in
                StoryPortionView(
                    storyPortionViewModel: storyPortionViewModel,
                    animationHandler: animationHandler,
                    deletePortion: StoriesViewModel.preview.deletePortion, 
                    onDisappear: { _ in }
                )
            },
            onDisappear: { _ in }
        )
    }()
}

extension StoryAnimationHandler {
    static let preview: StoryAnimationHandler = StoryAnimationHandler(
        storyId: PreviewData.stories[0].id,
        currentStoryAnimationHandler: StoriesAnimationHandler.preview
    )
}

extension StoriesAnimationHandler {
    static let preview: StoriesAnimationHandler = StoriesAnimationHandler(
        storiesHolder: StoriesViewModel.preview
    )
}
