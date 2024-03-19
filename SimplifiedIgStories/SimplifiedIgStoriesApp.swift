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
    
    let mediaSaver = LocalMediaSaver()
}

@main
struct SimplifiedIgStoriesApp: App {
    private let factory = AppComponentsFactory()
    
    var body: some Scene {
        WindowGroup {
            HomeView(
                storiesViewModel: factory.storiesViewModel,
                getStoryContainer: {
                    StoryContainer(
                        vm: factory.storiesViewModel,
                        getStoryView: { story in
                            StoryView(
                                storyId: story.id,
                                vm: StoryViewModel(
                                    storyId: story.id,
                                    parentViewModel: factory.storiesViewModel,
                                    fileManager: factory.fileManager,
                                    mediaSaver: factory.mediaSaver
                                )
                            )
                        })
                }
            )
        }
    }
}
