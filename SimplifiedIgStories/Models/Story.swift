//
//  Story.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/2/2022.
//

import Foundation

struct Story: Hashable, Codable, Identifiable {
    var id: Int
    var lastUpdate: Int
    var portionCount: Int
    var portions: [Portion]
    var user: User
    
    var dateAgo: Date {
        Date(timeIntervalSince1970: TimeInterval(lastUpdate))
    }
}

struct Portion: Hashable, Codable, Identifiable {
    var id: Int
    var imageName: String
}
