//
//  Story.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/02/2024.
//

import Foundation

struct Story: Equatable {
    let id: Int
    let lastUpdate: Date?
    let user: User
    let portions: [Portion]
}
