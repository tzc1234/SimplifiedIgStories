//
//  Portion.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 05/07/2024.
//

import Foundation

struct Portion: Equatable {
    let id: Int
    let resourceURL: URL?
    let duration: Double
    let type: ResourceType
}

enum ResourceType: String {
    case image
    case video
}
