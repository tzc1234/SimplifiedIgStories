//
//  LocalPortion.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 05/07/2024.
//

import Foundation

struct LocalPortion: Equatable {
    let id: Int
    let resourceURL: URL?
    let duration: Double
    let type: LocalResourceType
}

enum LocalResourceType: String {
    case image
    case video
}
