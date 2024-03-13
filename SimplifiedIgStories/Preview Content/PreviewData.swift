//
//  PreviewData.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/07/2022.
//

import Foundation

struct PreviewData {
    static let stories: [Story] = [
        Story(
            id: 0,
            lastUpdate: .now,
            portions: [
                Portion(id: 0, imageName: "sea1")
            ],
            user: User(
                id: 0,
                name: "User 0",
                avatarURL: Bundle.main.url(forResource: "sea1", withExtension: "jpg"),
                isCurrentUser: false
            )
        )
    ]
}
