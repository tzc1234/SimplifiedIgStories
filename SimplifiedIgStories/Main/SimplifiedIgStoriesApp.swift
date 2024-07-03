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
    private let portionViewModelCache = ComponentCache<Int, StoryPortionViewModel>()
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
                                getStoryPortionView: { index, portion in
                                    let portionViewModel = getStoryPortionViewModel(
                                        for: story,
                                        portion: portion
                                    )
                                    
                                    return StoryPortionView(
                                        portionIndex: index, 
                                        storyPortionViewModel: portionViewModel,
                                        animationHandler: storyAnimationHandler,
                                        deletePortion: storiesViewModel.deletePortion, 
                                        onDisappear: { portionId in
                                            portionViewModelCache.removeComponent(for: portionId)
                                        }
                                    )
                                },
                                onDisappear: { storyId in
                                    storyAnimationHandlerCache.removeComponent(for: storyId)
                                }
                            )
                        }
                    )
                }, 
                getStoryCameraView: {
                    StoryCameraView(viewModel: StoryCameraViewModel(
                        camera: factory.camera,
                        cameraAuthorizationTracker: factory.cameraAuthorizationTracker,
                        microphoneAuthorizationTracker: factory.microphoneAuthorizationTracker
                    ), getStoryPreview: { media, backBtnAction, postBtnAction in
                        StoryPreview(media: media, backBtnAction: backBtnAction, postBtnAction: postBtnAction)
                    })
                }
            )
        }
    }
    
    private func getStoryPortionViewModel(for story: Story, 
                                          portion: Portion) -> StoryPortionViewModel {
        let portionViewModel = if let viewModel = portionViewModelCache.getComponent(for: portion.id) {
            viewModel
        } else {
            StoryPortionViewModel(
                story: story,
                portion: portion,
                fileManager: factory.fileManager,
                mediaSaver: factory.mediaSaver
            )
        }
        
        portionViewModelCache.save(portionViewModel, for: portion.id)
        return portionViewModel
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
