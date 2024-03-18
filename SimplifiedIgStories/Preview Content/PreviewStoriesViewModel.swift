//
//  PreviewStoriesViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/03/2024.
//

import Foundation

extension StoriesViewModel {
    static var preview: StoriesViewModel {
        StoriesViewModel(fileManager: DummyFileManager(), storiesLoader: PreviewStoriesLoader())
    }
}

final class PreviewStoriesLoader: StoriesLoader {
    func load() async throws -> [LocalStory] {
        [
            LocalStory(
                id: 0,
                lastUpdate: nil,
                user: LocalUser(
                    id: 0,
                    name: "CurrentUser",
                    avatarURL: nil,
                    isCurrentUser: true
                ),
                portions: [
                    LocalPortion(
                        id: 0,
                        resourceURL: nil,
                        duration: .defaultStoryDuration,
                        type: .image
                    )
                ]
            ),
            LocalStory(
                id: 1,
                lastUpdate: .now,
                user: LocalUser(
                    id: 1,
                    name: "User1",
                    avatarURL: nil,
                    isCurrentUser: false
                ),
                portions: [
                    LocalPortion(
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
