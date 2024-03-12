//
//  Story.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/2/2022.
//

import Foundation

struct Story: Identifiable {
    let id: Int
    var lastUpdate: Date?
    var portions: [Portion]
    let user: User
    
    var hasPortion: Bool {
        portions.count > 0
    }
}
