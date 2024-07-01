//
//  DummyCamera.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 01/07/2024.
//

import Foundation
import Combine

final class DummyPhotoTaker: PhotoTaker {
    func getStatusPublisher() -> AnyPublisher<PhotoTakerStatus, Never> {
        Empty<PhotoTakerStatus, Never>().eraseToAnyPublisher()
    }
    
    func takePhoto(on mode: CameraFlashMode) {}
}

final class DummyVideoRecorder: VideoRecorder {
    func getStatusPublisher() -> AnyPublisher<VideoRecorderStatus, Never> {
        Empty<VideoRecorderStatus, Never>().eraseToAnyPublisher()
    }
    
    func startRecording() {}
    func stopRecording() {}
}

final class DummyCameraAuxiliary: CameraAuxiliary {
    func focus(on point: CGPoint) {}
    func zoom(to factor: CGFloat) {}
}

extension DefaultCamera {
    static let dummy = DefaultCamera(
        cameraCore: AVCameraCore(),
        photoTaker: DummyPhotoTaker(),
        videoRecorder: DummyVideoRecorder(),
        cameraAuxiliary: DummyCameraAuxiliary()
    )
}
