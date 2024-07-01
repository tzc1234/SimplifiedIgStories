//
//  Camera.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 01/07/2024.
//

import AVKit
import Combine

enum CameraStatus {
    case sessionStarted
    case sessionStopped
    case cameraSwitched
    case addPhotoOutputFailure
    case photoTaken(photo: UIImage)
    case imageConvertingFailure
    case recordingBegun
    case recordingFinished
    case videoProcessFailure
    case processedVideo(videoURL: URL)
    case addMovieFileOutputFailure
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

final class DefaultCamera: Camera {
    private let statusPublisher = PassthroughSubject<CameraStatus, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
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
        
        self.subscribeCameraPublisher()
        self.subscribePhotoTakerPublisher()
        self.subscribeVideoRecorderPublisher()
    }
    
    func getStatusPublisher() -> AnyPublisher<CameraStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
}

extension DefaultCamera {
    var cameraPosition: CameraPosition {
        cameraCore.cameraPosition
    }
    
    var videoPreviewLayer: CALayer {
        cameraCore.videoPreviewLayer
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
    
    private func subscribeCameraPublisher() {
        cameraCore
            .getStatusPublisher()
            .sink { [weak self] camStatus in
                guard let self else { return }
                
                switch camStatus {
                case .sessionStarted:
                    statusPublisher.send(.sessionStarted)
                case .sessionStopped:
                    statusPublisher.send(.sessionStopped)
                case .cameraSwitched:
                    statusPublisher.send(.cameraSwitched)
                }
            }
            .store(in: &subscriptions)
    }
}

extension DefaultCamera {
    func takePhoto(on flashMode: CameraFlashMode) {
        photoTaker.takePhoto(on: flashMode)
    }
    
    private func subscribePhotoTakerPublisher() {
        photoTaker
            .getStatusPublisher()
            .sink { [weak self] status in
                guard let self else { return }
                
                switch status {
                case .addPhotoOutputFailure:
                    statusPublisher.send(.addPhotoOutputFailure)
                case .photoTaken(let photo):
                    statusPublisher.send(.photoTaken(photo: photo))
                case .imageConvertingFailure:
                    statusPublisher.send(.imageConvertingFailure)
                }
            }
            .store(in: &subscriptions)
    }
}

extension DefaultCamera {
    func startRecording() {
        videoRecorder.startRecording()
    }
    
    func stopRecording() {
        videoRecorder.stopRecording()
    }
    
    private func subscribeVideoRecorderPublisher() {
        videoRecorder
            .getStatusPublisher()
            .sink { [weak self] status in
                guard let self else { return }
                
                switch status {
                case .recordingBegun:
                    statusPublisher.send(.recordingBegun)
                case .recordingFinished:
                    statusPublisher.send(.recordingFinished)
                case .videoProcessFailure:
                    statusPublisher.send(.videoProcessFailure)
                case .processedVideo(let videoURL):
                    statusPublisher.send(.processedVideo(videoURL: videoURL))
                case .addMovieFileOutputFailure:
                    statusPublisher.send(.addMovieFileOutputFailure)
                }
            }
            .store(in: &subscriptions)
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
