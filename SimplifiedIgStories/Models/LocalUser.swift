//
//  LocalUser.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 05/07/2024.
//

import Foundation

struct LocalUser: Equatable {
    let id: Int
    let name: String
    let avatarURL: URL?
    let isCurrentUser: Bool
}
