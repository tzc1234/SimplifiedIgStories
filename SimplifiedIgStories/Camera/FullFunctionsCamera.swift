//
//  FullFunctionsCamera.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 01/07/2024.
//

import AVKit
import Combine

enum FullFunctionsCameraStatus {
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

protocol FullFunctionsCamera {
    var cameraPosition: CameraPosition { get }
    var videoPreviewLayer: CALayer { get }
    
    func getStatusPublisher() -> AnyPublisher<FullFunctionsCameraStatus, Never>
    func startSession()
    func stopSession()
    func switchCamera()
    
    func takePhoto(on flashMode: CameraFlashMode)
    
    func startRecording()
    func stopRecording()
    
    func focus(on point: CGPoint)
    func zoom(to factor: CGFloat)
}

final class DefaultFullFunctionsCamera: FullFunctionsCamera {
    private let statusPublisher = PassthroughSubject<FullFunctionsCameraStatus, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    private let camera: Camera
    private let photoTaker: PhotoTaker
    private let videoRecorder: VideoRecorder
    private let cameraAuxiliary: CameraAuxiliary
    
    init(camera: Camera, photoTaker: PhotoTaker, videoRecorder: VideoRecorder, cameraAuxiliary: CameraAuxiliary) {
        self.camera = camera
        self.photoTaker = photoTaker
        self.videoRecorder = videoRecorder
        self.cameraAuxiliary = cameraAuxiliary
        
        self.subscribeCameraPublisher()
        self.subscribePhotoTakerPublisher()
        self.subscribeVideoRecorderPublisher()
    }
    
    func getStatusPublisher() -> AnyPublisher<FullFunctionsCameraStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
}

extension DefaultFullFunctionsCamera {
    var cameraPosition: CameraPosition {
        camera.cameraPosition
    }
    
    var videoPreviewLayer: CALayer {
        camera.videoPreviewLayer
    }
    
    func startSession() {
        camera.startSession()
    }
    
    func stopSession() {
        camera.stopSession()
    }
    
    func switchCamera() {
        camera.switchCamera()
    }
    
    private func subscribeCameraPublisher() {
        camera
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

extension DefaultFullFunctionsCamera {
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

extension DefaultFullFunctionsCamera {
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

extension DefaultFullFunctionsCamera {
    func focus(on point: CGPoint) {
        cameraAuxiliary.focus(on: point)
    }
    
    func zoom(to factor: CGFloat) {
        cameraAuxiliary.zoom(to: factor)
    }
}
