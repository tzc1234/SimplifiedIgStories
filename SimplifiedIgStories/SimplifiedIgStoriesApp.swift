//
//  SimplifiedIgStoriesApp.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/2/2022.
//

import SwiftUI

final class AppComponentsFactory {
    private let fileManager = LocalFileManager()
    
    private let storiesDataURL = Bundle.main.url(forResource: "storiesData.json", withExtension: nil)
    private lazy var dataClient = storiesDataURL.map(FileDataClient.init)
    private lazy var storiesLoader = dataClient.map(LocalStoriesLoader.init)
    
    private(set) lazy var storiesViewModel = StoriesViewModel(fileManager: fileManager, storiesLoader: storiesLoader)
}

@main
struct SimplifiedIgStoriesApp: App {
    private let factory = AppComponentsFactory()
    
    var body: some Scene {
        WindowGroup {
            HomeView(storiesViewModel: factory.storiesViewModel)
        }
    }
}
