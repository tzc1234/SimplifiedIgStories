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
    private let storyViewModelCache = ComponentCache<Int, StoryViewModel>()
    private let storyAnimationHandlerCache = ComponentCache<Int, StoryAnimationHandler>()
    
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
                            let storyAnimationHandler = getStoryAnimationHandler(for: story.id)
                            
                            return StoryView(
                                story: story,
                                animationHandler: storyAnimationHandler, 
                                getStoryPortionView: { portion in
                                    let storyViewModel = getStoryViewModel(
                                        for: story,
                                        portion: portion,
                                        animationHandler: storyAnimationHandler
                                    )
                                    
                                    return StoryPortionView(
                                        storyViewModel: storyViewModel,
                                        animationHandler: storyAnimationHandler,
                                        portionMutationHandler: storiesViewModel, 
                                        onDisappear: { portionId in
                                            storyViewModelCache.removeComponent(for: portionId)
                                        }
                                    )
                                },
                                onDisappear: { storyId in
                                    storyAnimationHandlerCache.removeComponent(for: storyId)
                                }
                            )
                        }
                    )
                }
            )
        }
    }
    
    private func getStoryViewModel(for story: Story, portion: Portion, animationHandler: StoryAnimationHandler) -> StoryViewModel {
        let storyViewModel = if let viewModel = storyViewModelCache.getComponent(for: portion.id) {
            viewModel
        } else {
            StoryViewModel(
                story: story,
                portion: portion,
                fileManager: factory.fileManager,
                mediaSaver: factory.mediaSaver,
                pauseAnimation: animationHandler.pausePortionAnimation,
                resumeAnimation: animationHandler.resumePortionAnimation
            )
        }
        
        storyViewModelCache.save(storyViewModel, for: portion.id)
        return storyViewModel
    }
    
    private func getStoryAnimationHandler(for storyId: Int) -> StoryAnimationHandler {
        let animationHandler = if let handler = storyAnimationHandlerCache.getComponent(for: storyId) {
            handler
        } else {
            StoryAnimationHandler(
                storyId: storyId,
                currentStoryAnimationHandler: storiesAnimationHandler
            )
        }
        
        storyAnimationHandlerCache.save(animationHandler, for: storyId)
        return animationHandler
    }
}
