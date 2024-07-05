//
//  PreviewStoriesViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/03/2024.
//

import Foundation

extension StoriesViewModel {
    static var preview: StoriesViewModel {
        StoriesViewModel(
            storiesLoader: PreviewStoriesLoader(),
            fileManager: DummyFileManager()
        )
    }
}

final class PreviewStoriesLoader: StoriesLoader {
    func load() async throws -> [Story] {
        [
            Story(
                id: 0,
                lastUpdate: nil,
                user: User(
                    id: 0,
                    name: "CurrentUser",
                    avatarURL: nil,
                    isCurrentUser: true
                ),
                portions: [
                    Portion(
                        id: 0,
                        resourceURL: nil,
                        duration: .defaultStoryDuration,
                        type: .image
                    )
                ]
            ),
            Story(
                id: 1,
                lastUpdate: .now,
                user: User(
                    id: 1,
                    name: "User1",
                    avatarURL: nil,
                    isCurrentUser: false
                ),
                portions: [
                    Portion(
                        id: 1,
                        resourceURL: nil,
                        duration: .defaultStoryDuration,
                        type: .image
                    )
                ]
            )
        ]
    }
}
