//
//  DefaultCamera.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 03/07/2024.
//

import AVKit
import Combine

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
                    break
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
                    break
                case let .photoTaken(photo):
                    statusPublisher.send(.processedMedia(.image(photo)))
                case .imageConvertingFailure:
                    break
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
                    break
                case let .processedVideo(videoURL):
                    statusPublisher.send(.processedMedia(.video(videoURL)))
                case .addMovieFileOutputFailure:
                    break
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
