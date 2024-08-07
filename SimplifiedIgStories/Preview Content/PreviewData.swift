//
//  PreviewData.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/07/2022.
//

import Foundation

struct PreviewData {
    static let stories: [StoryDTO] = [
        StoryDTO(
            id: 0,
            lastUpdate: .now,
            user: UserDTO(
                id: 0,
                name: "User 0",
                avatarURL: Bundle.main.url(forResource: "sea1", withExtension: "jpg"),
                isCurrentUser: false
            ),
            portions: [
                PortionDTO(
                    id: 0,
                    duration: .defaultStoryDuration,
                    resourceURL: Bundle.main.url(forResource: "sea1", withExtension: "jpg"),
                    type: .image
                ),
                PortionDTO(
                    id: 1,
                    duration: .defaultStoryDuration,
                    resourceURL: Bundle.main.url(forResource: "sea2", withExtension: "jpg"),
                    type: .image
                )
            ]
        )
    ]
}
