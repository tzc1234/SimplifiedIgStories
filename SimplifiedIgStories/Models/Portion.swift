//
//  Portion.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 7/3/2022.
//

import Foundation

struct Portion: Hashable, Codable, Identifiable {
    var id: Int
    var imageName: String?
    var videoName: String?
    var videoDuration: Double?
    
    var videoUrl: URL? {
        guard let videoName = videoName else { return nil }
        guard let videoPath = Bundle.main.path(forResource: videoName, ofType: "mp4") else {
            return nil
        }
        return URL(fileURLWithPath: videoPath)
    }
    
    var duration: Double {
        guard videoUrl != nil, let videoDuration = videoDuration else {
            return 5.0 // *** Default duration.
        }
        return videoDuration
    }
    
}