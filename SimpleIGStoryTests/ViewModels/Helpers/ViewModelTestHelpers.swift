//
//  ViewModelTestHelpers.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 22/03/2024.
//

import Foundation
@testable import Simple_IG_Story

func makePortion(id: Int = 0, resourceURL: URL? = nil, type: ResourceType = .image) -> Portion {
    Portion(id: id, duration: 1, resourceURL: resourceURL, type: type)
}

func makeStory(id: Int = 0, portions: [Portion] = [], isCurrentUser: Bool = false) -> Story {
    Story(
        id: id,
        lastUpdate: nil,
        user: User(
            id: 0,
            name: "user",
            avatarURL: nil,
            isCurrentUser: isCurrentUser
        ),
        portions: portions
    )
}