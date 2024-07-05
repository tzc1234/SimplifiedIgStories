//
//  UserDTO.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/2/2022.
//

import Foundation

struct UserDTO: Identifiable, Equatable {
    let id: Int
    let name: String
    let avatarURL: URL?
    let isCurrentUser: Bool
    
    var title: String {
        isCurrentUser ? "Your story" : name
    }
}
