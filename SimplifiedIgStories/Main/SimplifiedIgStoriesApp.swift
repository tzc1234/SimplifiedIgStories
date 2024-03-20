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
    
    private var storiesAnimationHandler: StoriesAnimationHandler {
        factory.storiesAnimationHandler
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView(
                storiesViewModel: storiesViewModel, 
                getStoryIconsView: {
                    StoryIconsView(animationHandler: storiesAnimationHandler)
                },
                getStoryContainer: {
                    StoryContainer(
                        animationHandler: storiesAnimationHandler,
                        getStoryView: { story in
                            let storyViewModel = getStoryViewModel(for: story.id)
                            let animationHandler = getAnimationHandler(for: story.id, storyViewModel: storyViewModel)
                            
                            return StoryView(
                                story: story,
                                shouldCubicRotation: storiesAnimationHandler.shouldCubicRotation,
                                storyViewModel: storyViewModel,
                                animationHandler: animationHandler, 
                                portionMutationHandler: storiesViewModel,
                                getProgressBar: {
                                    ProgressBar(
                                        story: story,
                                        currentStoryId: storiesAnimationHandler.currentStoryId,
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
            StoryViewModel(storyId: storyId)
        }
        
        storyViewModelCache.save(storyViewModel, for: storyId)
        return storyViewModel
    }
    
    private func getAnimationHandler(for storyId: Int, storyViewModel: StoryViewModel) -> StoryAnimationHandler {
        let animationHandler = if let handler = animationHandlerCache.getComponent(for: storyId) {
            handler
        } else {
            StoryAnimationHandler(
                storyId: storyId,
                currentStoryHandler: storiesAnimationHandler,
                animationShouldPausePublisher: storyViewModel.$showConfirmationDialog
                    .combineLatest(storyViewModel.$noticeMsg)
                    .map { $0 || !$1.isEmpty }
                    .eraseToAnyPublisher()
            )
        }
        
        animationHandlerCache.save(animationHandler, for: storyId)
        return animationHandler
    }
}
