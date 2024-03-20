//
//  SimplifiedIgStoriesApp.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/2/2022.
//

import SwiftUI
import Combine

@main
struct SimplifiedIgStoriesApp: App {
    private let factory = AppComponentsFactory()
    private let storyViewModelCache = StoryComponentCache<StoryViewModel>()
    private let animationHandlerCache = StoryComponentCache<StoryAnimationHandler>()
    
    private var storiesViewModel: StoriesViewModel {
        factory.storiesViewModel
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView(
                storiesViewModel: storiesViewModel,
                getStoryContainer: {
                    StoryContainer(
                        storiesViewModel: storiesViewModel,
                        getStoryView: { story in
                            let storyViewModel = getStoryViewModel(for: story.id)
                            let animationHandler = getAnimationHandler(for: story, storyViewModel: storyViewModel)
                            
                            return StoryView(
                                story: story,
                                shouldCubicRotation: storiesViewModel.shouldCubicRotation,
                                storyViewModel: storyViewModel, 
                                animationHandler: animationHandler, 
                                portionMutationHandler: storiesViewModel,
                                getProgressBar: {
                                    ProgressBar(
                                        story: story,
                                        currentStoryId: storiesViewModel.currentStoryId,
                                        animationHandler: animationHandler
                                    )
                                },
                                onDisappear: { storyId in
                                    storyViewModelCache.removeComponent(for: storyId)
                                    animationHandlerCache.removeComponent(for: storyId)
                                }
                            )
                        }
                    )
                }
            )
        }
    }
    
    private func getStoryViewModel(for storyId: Int) -> StoryViewModel {
        let storyViewModel = if let viewModel = storyViewModelCache.getComponent(for: storyId) {
            viewModel
        } else {
            StoryViewModel(storyId: storyId, fileManager: factory.fileManager)
        }
        
        storyViewModelCache.save(storyViewModel, for: storyId)
        return storyViewModel
    }
    
    private func getAnimationHandler(for story: Story, storyViewModel: StoryViewModel) -> StoryAnimationHandler {
        let animationHandler = if let handler = animationHandlerCache.getComponent(for: story.id) {
            handler
        } else {
            StoryAnimationHandler(
                storyId: story.id,
                currentStoryHandler: storiesViewModel,
                animationShouldPausePublisher: storyViewModel.$showConfirmationDialog
                    .combineLatest(storyViewModel.$showNoticeLabel)
                    .map { $0 || $1 }
                    .eraseToAnyPublisher()
            )
        }
        
        animationHandlerCache.save(animationHandler, for: story.id)
        return animationHandler
    }
}
