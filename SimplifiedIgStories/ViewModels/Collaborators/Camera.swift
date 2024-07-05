//
//  Camera.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 01/07/2024.
//

import UIKit
import Combine

enum Media {
    case photo(UIImage)
    case video(URL)
}

enum CameraStatus {
    case sessionStarted
    case sessionStopped
    case recordingBegun
    case recordingFinished
    case processedMedia(Media)
}

protocol Camera {
    var cameraPosition: CameraPosition { get }
    var videoPreviewLayer: CALayer { get }
    
    func getStatusPublisher() -> AnyPublisher<CameraStatus, Never>
    func startSession()
    func stopSession()
    func switchCamera()
    func takePhoto(on flashMode: CameraFlashMode)
    func startRecording()
    func stopRecording()
    func focus(on point: CGPoint)
    func zoom(to factor: CGFloat)
}
