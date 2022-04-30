//
//  User.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/2/2022.
//

import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let avatar: String
    let isCurrentUser: Bool
    
    var title: String {
        isCurrentUser ? "Your story" : name
    }
}
