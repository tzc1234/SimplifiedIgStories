//
//  SimplifiedIgStoriesApp.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/2/2022.
//

import SwiftUI
import Combine

final class AppComponentsFactory {
    let fileManager = LocalFileManager()
    
    // storiesDataURL should not be nil, since storiesData.json is already embedded in Resource directory.
    private let storiesDataURL = Bundle.main.url(forResource: "storiesData.json", withExtension: nil)!
    private lazy var dataClient = FileDataClient(url: storiesDataURL)
    private lazy var storiesLoader = LocalStoriesLoader(client: dataClient)
    
    private(set) lazy var storiesViewModel = StoriesViewModel(fileManager: fileManager, storiesLoader: storiesLoader)
    
    private let mediaStore = PHPPhotoMediaStore()
    private(set) lazy var mediaSaver = LocalMediaSaver(store: mediaStore)
}

final class ComponentCache<T> {
    private var cache = [Int: T]()
    
    func save(_ component: T, for storyId: Int) {
        cache[storyId] = component
    }
    
    func getComponent(for storyId: Int) -> T? {
        cache[storyId]
    }
    
    func removeComponent(for storyId: Int) {
        cache[storyId] = nil
    }
}

@main
struct SimplifiedIgStoriesApp: App {
    private let factory = AppComponentsFactory()
    private let storyViewModelCache = ComponentCache<StoryViewModel>()
    private let animationHandlerCache = ComponentCache<StoryAnimationHandler>()
    
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
                            let animationHandler = getAnimationHandler(for: story)
                            let storyViewModel = getStoryViewModel(for: story.id, animationHandler: animationHandler)
                            
                            animationHandler.subscribe(
                                animationShouldPausePublisher: storyViewModel.$showConfirmationDialog
                                    .combineLatest(storyViewModel.$showNoticeLabel)
                                    .map { $0 || $1 }
                                    .eraseToAnyPublisher()
                            )
                            
                            return StoryView(
                                story: story,
                                shouldCubicRotation: storiesViewModel.shouldCubicRotation,
                                storyViewModel: storyViewModel, 
                                animationHandler: animationHandler,
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
                        })
                }
            )
        }
    }
    
    private func getStoryViewModel(for storyId: Int, animationHandler: StoryAnimationHandler) -> StoryViewModel {
        let storyViewModel = if let viewModel = storyViewModelCache.getComponent(for: storyId) {
            viewModel
        } else {
            StoryViewModel(
                storyId: storyId,
                parentViewModel: storiesViewModel,
                fileManager: factory.fileManager,
                mediaSaver: factory.mediaSaver,
                currentPortion: { animationHandler.currentPortion },
                currentPortionIndex: { animationHandler.currentPortionIndex },
                moveToNewCurrentPortion: animationHandler.moveToNewCurrentPortion
            )
        }
        
        storyViewModelCache.save(storyViewModel, for: storyId)
        return storyViewModel
    }
    
    private func getAnimationHandler(for story: Story) -> StoryAnimationHandler {
        let animationHandler = if let handler = animationHandlerCache.getComponent(for: story.id) {
            handler
        } else {
            StoryAnimationHandler(
                storyId: story.id,
                isAtFirstStory: { storiesViewModel.firstCurrentStoryId == story.id },
                isAtLastStory: { storiesViewModel.isAtLastStory },
                isCurrentStory: { storiesViewModel.currentStoryId == story.id },
                moveToPreviousStory: storiesViewModel.moveToPreviousStory,
                moveToNextStory: storiesViewModel.moveToNextStory,
                getPortions: { storyId in
                    storiesViewModel.stories.first(where: { $0.id == storyId })?.portions ?? []
                },
                isSameStoryAfterDragging: { storiesViewModel.isSameStoryAfterDragging },
                isDraggingPublisher: storiesViewModel.getIsDraggingPublisher
            )
        }
        
        animationHandlerCache.save(animationHandler, for: story.id)
        return animationHandler
    }
}
