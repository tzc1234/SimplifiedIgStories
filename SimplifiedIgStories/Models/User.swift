//
//  User.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/2/2022.
//

import Foundation

struct User: Codable, Hashable, Identifiable {
    var id: Int
    var name: String
    var avatar: String
    var isCurrentUser: Bool
    
    var title: String {
        isCurrentUser ? "Your story" : name
    }
}
