//
//  Portion.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 7/3/2022.
//

import Foundation

struct Portion: Identifiable, Equatable {
    var id: Int
    var duration: Double
    var resourceURL: URL?
    var type: ResourceType
    
    var imageURL: URL? {
        type == .image ? resourceURL : nil
    }
    
    var videoURL: URL? {
        type == .video ? resourceURL : nil
    }
}

enum ResourceType: String {
    case image
    case video
}
