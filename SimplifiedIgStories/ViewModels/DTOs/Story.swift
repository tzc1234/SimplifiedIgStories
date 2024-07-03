//
//  Story.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/2/2022.
//

import Foundation

struct Story: Identifiable, Equatable {
    let id: Int
    var lastUpdate: Date?
    let user: User
    var portions: [Portion]
    
    var hasPortion: Bool {
        portions.count > 0
    }
}
