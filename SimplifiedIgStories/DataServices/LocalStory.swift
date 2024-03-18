//
//  LocalStory.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/02/2024.
//

import Foundation

struct LocalStory: Equatable {
    let id: Int
    let lastUpdate: Date?
    let user: LocalUser
    let portions: [LocalPortion]
}

struct LocalUser: Equatable {
    let id: Int
    let name: String
    let avatarURL: URL?
    let isCurrentUser: Bool
}

struct LocalPortion: Equatable {
    let id: Int
    let resourceURL: URL?
    let duration: Double
    let type: LocalResourceType
}

enum LocalResourceType: String {
    case image
    case video
}
