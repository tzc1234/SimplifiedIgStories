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
        let portions = story.portions
        let storiesViewModel = StoriesViewModel.preview
        let animationHandler = StoryAnimationHandler.preview
        
        return StoryView(
            story: story,
            animationHandler: animationHandler,
            getStoryPortionView: { index, portion in
                let storyPortionViewModel = StoryPortionViewModel(
                    story: story,
                    portion: portion,
                    fileManager: DummyFileManager(),
                    mediaSaver: DummyMediaSaver()
                )
                
                return StoryPortionView(
                    portionIndex: 0,
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
    static let preview = StoryAnimationHandler(
        storyId: PreviewData.stories[0].id,
        currentStoryAnimationHandler: StoriesAnimationHandler.preview
    )
}

extension StoriesAnimationHandler {
    static let preview = StoriesAnimationHandler(storiesHolder: StoriesHolderStub(stories: PreviewData.stories))
}

final class StoriesHolderStub: ObservableObject, StoriesHolder {
    let stories: [StoryDTO]
    
    init(stories: [StoryDTO]) {
        self.stories = stories
    }
}
