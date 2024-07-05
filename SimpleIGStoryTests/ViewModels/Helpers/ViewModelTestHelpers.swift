//
//  ViewModelTestHelpers.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 22/03/2024.
//

import UIKit
@testable import Simple_IG_Story

func makePortion(id: Int = 0, resourceURL: URL? = nil, type: ResourceType = .image) -> PortionDTO {
    PortionDTO(id: id, duration: 1, resourceURL: resourceURL, type: type)
}

func makeStory(id: Int = 0, portions: [PortionDTO] = [], isCurrentUser: Bool = false) -> StoryDTO {
    StoryDTO(
        id: id,
        lastUpdate: nil,
        user: UserDTO(
            id: 0,
            name: "user",
            avatarURL: nil,
            isCurrentUser: isCurrentUser
        ),
        portions: portions
    )
}

func anyUIImage() -> UIImage {
    UIImage.make(withColor: .gray)
}
