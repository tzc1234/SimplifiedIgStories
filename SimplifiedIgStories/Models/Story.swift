//
//  Story.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/2/2022.
//

import Foundation

struct Story: Hashable, Codable, Identifiable {
    var id: Int
    var lastUpdate: Int?
    var portions: [Portion]
    var user: User
    
    var lastUpdateDate: Date? {
        guard let lastUpdate = lastUpdate else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(lastUpdate))
    }
    
    var hasPortion: Bool {
        return portions.count > 0
    }
}

struct Portion: Hashable, Codable, Identifiable {
    var id: Int
    var imageName: String
}
