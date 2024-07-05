//
//  StoryDTO.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/2/2022.
//

import Foundation

struct StoryDTO: Identifiable, Equatable {
    let id: Int
    var lastUpdate: Date?
    let user: UserDTO
    var portions: [PortionDTO]
    
    var hasPortion: Bool {
        portions.count > 0
    }
}
