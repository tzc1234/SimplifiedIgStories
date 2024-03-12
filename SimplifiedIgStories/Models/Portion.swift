//
//  Portion.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 7/3/2022.
//

import Foundation

struct Portion: Identifiable {
    var id: Int
    var imageName: String?
    var videoName: String?
    var videoDuration: Double?
    
    var imageUrl: URL?
    var videoUrlFromCam: URL?
    
    var videoUrl: URL? {
        guard let videoName, let videoPath = Bundle.main.path(forResource: videoName, ofType: "mp4") else {
            return nil
        }
        
        return URL(fileURLWithPath: videoPath)
    }
    
    var duration: Double {
        guard let videoDuration = videoDuration else {
            return .defaultStoryDuration
        }
        
        return videoDuration
    }
}
