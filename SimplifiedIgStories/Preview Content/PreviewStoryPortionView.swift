//
//  PreviewStoryPortionView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/03/2024.
//

import SwiftUI

extension StoryPortionView {
    static let preview: StoryPortionView = {
        let story = PreviewData.stories[0]
        let portion = story.portions[0]
        return StoryPortionView(
            portionIndex: 0, 
            storyPortionViewModel: StoryPortionViewModel(
                story: story,
                portion: portion,
                fileManager: DummyFileManager(),
                mediaSaver: DummyMediaSaver()
            ),
            animationHandler: .preview,
            deletePortion: StoriesViewModel.preview.deletePortion,
            onDisappear: { _ in }
        )
    }()
}
