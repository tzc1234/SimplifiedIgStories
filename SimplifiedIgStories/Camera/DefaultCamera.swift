//
//  DefaultCamera.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 03/07/2024.
//

import AVKit
import Combine

final class DefaultCamera: Camera {
    private let cameraCore: CameraCore
    private let photoTaker: PhotoTaker
    private let videoRecorder: VideoRecorder
    private let cameraAuxiliary: CameraAuxiliary
    
    init(cameraCore: CameraCore,
         photoTaker: PhotoTaker,
         videoRecorder: VideoRecorder,
         cameraAuxiliary: CameraAuxiliary) {
        self.cameraCore = cameraCore
        self.photoTaker = photoTaker
        self.videoRecorder = videoRecorder
        self.cameraAuxiliary = cameraAuxiliary
    }
    
    func getStatusPublisher() -> AnyPublisher<CameraStatus, Never> {
        cameraCorePublisher
            .merge(with: photoTakerPublisher, videoRecorderPublisher)
            .eraseToAnyPublisher()
    }
}

extension DefaultCamera {
    var cameraPosition: CameraPosition {
        cameraCore.cameraPosition
    }
    
    var videoPreviewLayer: CALayer {
        cameraCore.videoPreviewLayer
    }
    
    private var cameraCorePublisher: AnyPublisher<CameraStatus, Never> {
        cameraCore
            .getStatusPublisher()
            .compactMap { status -> CameraStatus? in
                switch status {
                case .sessionStarted:
                    return .sessionStarted
                case .sessionStopped:
                    return .sessionStopped
                case .cameraSwitched:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    func startSession() {
        cameraCore.startSession()
    }
    
    func stopSession() {
        cameraCore.stopSession()
    }
    
    func switchCamera() {
        cameraCore.switchCamera()
    }
}

extension DefaultCamera {
    private var photoTakerPublisher: AnyPublisher<CameraStatus, Never> {
        photoTaker
            .getStatusPublisher()
            .compactMap { status -> CameraStatus? in
                switch status {
                case .addPhotoOutputFailure:
                    return nil
                case let .photoTaken(photo):
                    return .processedMedia(.photo(photo))
                case .imageConvertingFailure:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    func takePhoto(on flashMode: CameraFlashMode) {
        photoTaker.takePhoto(on: flashMode)
    }
}

extension DefaultCamera {
    private var videoRecorderPublisher: AnyPublisher<CameraStatus, Never> {
        videoRecorder
            .getStatusPublisher()
            .compactMap { status -> CameraStatus? in
                switch status {
                case .recordingBegun:
                    return .recordingBegun
                case .recordingFinished:
                    return .recordingFinished
                case .videoProcessFailure:
                    return nil
                case let .processedVideo(videoURL):
                    return .processedMedia(.video(videoURL))
                case .addMovieFileOutputFailure:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    func startRecording() {
        videoRecorder.startRecording()
    }
    
    func stopRecording() {
        videoRecorder.stopRecording()
    }
}

extension DefaultCamera {
    func focus(on point: CGPoint) {
        cameraAuxiliary.focus(on: point)
    }
    
    func zoom(to factor: CGFloat) {
        cameraAuxiliary.zoom(to: factor)
    }
}
