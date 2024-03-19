//
//  SimplifiedIgStoriesApp.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/2/2022.
//

import SwiftUI

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

final class StoryViewModelCache {
    private var storyViewModelCache = [Int: StoryViewModel]()
    
    func saveStoryViewModel(_ storyViewModel: StoryViewModel, for storyId: Int) {
        storyViewModelCache[storyId] = storyViewModel
    }
    
    func getStoryViewModel(for storyId: Int) -> StoryViewModel? {
        storyViewModelCache[storyId]
    }
    
    func removeStoryViewModel(for storyId: Int) {
        storyViewModelCache[storyId] = nil
    }
}

@main
struct SimplifiedIgStoriesApp: App {
    private let factory = AppComponentsFactory()
    private let cache = StoryViewModelCache()
    
    var body: some Scene {
        WindowGroup {
            HomeView(
                storiesViewModel: factory.storiesViewModel,
                getStoryContainer: {
                    StoryContainer(
                        storiesViewModel: factory.storiesViewModel,
                        getStoryView: { story in
                            let storyViewModel = if let viewModel = cache.getStoryViewModel(for: story.id) {
                                viewModel
                            } else {
                                StoryViewModel(
                                    storyId: story.id,
                                    parentViewModel: factory.storiesViewModel,
                                    fileManager: factory.fileManager,
                                    mediaSaver: factory.mediaSaver
                                )
                            }
                            
                            cache.saveStoryViewModel(storyViewModel, for: story.id)
                            
                            return StoryView(
                                story: story,
                                shouldCubicRotation: factory.storiesViewModel.shouldCubicRotation,
                                storyViewModel: storyViewModel, 
                                getProgressBar: {
                                    ProgressBar(
                                        story: story,
                                        currentStoryId: factory.storiesViewModel.currentStoryId,
                                        storyViewModel: storyViewModel
                                    )
                                },
                                onDisappear: cache.removeStoryViewModel
                            )
                        })
                }
            )
        }
    }
}
