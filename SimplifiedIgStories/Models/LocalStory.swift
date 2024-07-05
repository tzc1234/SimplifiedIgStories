//
//  LocalStory.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/02/2024.
//

import Foundation

struct LocalStory: Equatable {
    let id: Int
    let lastUpdate: Date?
    let user: LocalUser
    let portions: [LocalPortion]
}
