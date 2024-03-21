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
    private let storyPortionViewModelCache = ComponentCache<Int, StoryPortionViewModel>()
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
                                    let storyPortionViewModel = getStoryPortionViewModel(
                                        for: story,
                                        portion: portion,
                                        animationHandler: storyAnimationHandler
                                    )
                                    
                                    return StoryPortionView(
                                        storyPortionViewModel: storyPortionViewModel,
                                        animationHandler: storyAnimationHandler,
                                        portionMutationHandler: storiesViewModel, 
                                        onDisappear: { portionId in
                                            storyPortionViewModelCache.removeComponent(for: portionId)
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
    
    private func getStoryPortionViewModel(for story: Story, 
                                          portion: Portion,
                                          animationHandler: StoryAnimationHandler) -> StoryPortionViewModel {
        let storyPortionViewModel = if let viewModel = storyPortionViewModelCache.getComponent(for: portion.id) {
            viewModel
        } else {
            StoryPortionViewModel(
                story: story,
                portion: portion,
                fileManager: factory.fileManager,
                mediaSaver: factory.mediaSaver,
                pauseAnimation: animationHandler.pausePortionAnimation,
                resumeAnimation: animationHandler.resumePortionAnimation
            )
        }
        
        storyPortionViewModelCache.save(storyPortionViewModel, for: portion.id)
        return storyPortionViewModel
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
