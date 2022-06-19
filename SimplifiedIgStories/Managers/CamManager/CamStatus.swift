//
//  CamStatus.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/06/2022.
//

import AVFoundation
import AVKit

enum CamStatus {
    case sessionStarted
    case sessionStopped
    
    case photoTaken(photo: UIImage)
    case processingPhotoFailure(err: Error)
    case processingPhotoDataFailure
    case convertToUIImageFailure
    
    case recordingVideoBegun
    case recordingVideoFinished
    
    case processingVideoFailure(err: Error)
    case processingVideoFinished(videoUrl: URL)
    case cameraSwitched(camPosition: AVCaptureDevice.Position)
}
