//
//  StoryCamViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/03/2022.
//

import Foundation
import SwiftUI

final class StoryCamViewModel: ObservableObject {
    @Published var cameraSelection: SwiftyCamViewController.CameraSelection = .rear
    @Published var enableVideoRecordBtn = false
    @Published var flashMode: FlashMode = .off
    
    @Published var shouldPhotoTake = false
    var lastTakenImage: UIImage?
    @Published var photoDidTake = false
    
    @Published var videoRecordingStatus: VideoRecordingStatus = .none
    var lastVideoUrl: URL?
    @Published var videoDidRecord = false
    
    enum FlashMode {
        case on, off, auto
        
        var swiftyCamFlashMode: SwiftyCamViewController.FlashMode {
            switch self {
            case .auto: return .auto
            case .on: return .on
            case .off: return .off
            }
        }
        
        var systemImageName: String {
            switch self {
            case .auto: return "bolt.badge.a.fill"
            case .on: return "bolt.fill"
            case .off: return  "bolt.slash.fill"
            }
        }
    }
    
    enum VideoRecordingStatus {
        case none, start, stop
    }
}
