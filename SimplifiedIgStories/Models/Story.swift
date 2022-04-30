//
//  Story.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/2/2022.
//

import Foundation

struct Story: Codable, Identifiable {
    let id: Int
    var lastUpdate: TimeInterval?
    var portions: [Portion]
    let user: User
    
    var lastUpdateDate: Date? {
        guard let lastUpdate = lastUpdate else { return nil }
        return Date(timeIntervalSince1970: lastUpdate)
    }
    
    var hasPortion: Bool {
        return portions.count > 0
    }
}
