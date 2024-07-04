//
//  StoryCameraViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/03/2022.
//

import AVKit
import Combine

@MainActor final class StoryCameraViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()
    
    @Published private(set) var isCameraPermissionGranted = false
    @Published private(set) var isMicrophonePermissionGranted = false
    
    @Published var flashMode = CameraFlashMode.off
    @Published private(set) var enableVideoRecordButton = false
    
    private(set) var media: Media?
    @Published var showPreview = false {
        didSet {
            if showPreview {
                camera.stopSession()
            } else {
                media = nil
                camera.startSession()
            }
        }
    }
    
    @Published var isVideoRecording: Bool? {
        willSet {
            newValue.map { $0 ? camera.startRecording() : camera.stopRecording() }
        }
    }
    
    private let camera: Camera
    private let cameraAuthorizationTracker: DeviceAuthorizationTracker
    private let microphoneAuthorizationTracker: DeviceAuthorizationTracker

    init(camera: Camera,
         cameraAuthorizationTracker: DeviceAuthorizationTracker,
         microphoneAuthorizationTracker: DeviceAuthorizationTracker) {
        self.camera = camera
        self.cameraAuthorizationTracker = cameraAuthorizationTracker
        self.microphoneAuthorizationTracker = microphoneAuthorizationTracker
        
        self.subscribeCamMangerPublishers()
    }
}

extension StoryCameraViewModel {
    var arePermissionsGranted: Bool {
        isCameraPermissionGranted && isMicrophonePermissionGranted
    }
    
    var videoPreviewLayer: CALayer {
        camera.videoPreviewLayer
    }
}

extension StoryCameraViewModel {
    func checkPermissions() {
        cameraAuthorizationTracker.startTracking()
        microphoneAuthorizationTracker.startTracking()
    }
    
    func startCameraSession() {
        camera.startSession()
    }
    
    func stopCameraSession() {
        camera.stopSession()
    }
    
    func switchCamera() {
        camera.switchCamera()
    }
    
    func takePhoto() {
        camera.takePhoto(on: flashMode)
    }
    
    func focus(on point: CGPoint) {
        camera.focus(on: point)
    }
    
    func zoom(to factor: CGFloat) {
        camera.zoom(to: factor)
    }
}

extension StoryCameraViewModel {
    private func subscribeCamMangerPublishers() {
        cameraAuthorizationTracker
            .getPublisher()
            .receive(on: DispatchQueue.immediateWhenOnMainQueueScheduler)
            .sink { [weak self] isGranted in
                self?.isCameraPermissionGranted = isGranted
            }
            .store(in: &subscriptions)
        
        microphoneAuthorizationTracker
            .getPublisher()
            .receive(on: DispatchQueue.immediateWhenOnMainQueueScheduler)
            .sink { [weak self] isGranted in
                self?.isMicrophonePermissionGranted = isGranted
            }
            .store(in: &subscriptions)
        
        camera
            .getStatusPublisher()
            .receive(on: DispatchQueue.immediateWhenOnMainQueueScheduler)
            .sink { [weak self] camStatus in
                guard let self else { return }
                
                switch camStatus {
                case .sessionStarted:
                    print("Camera session did start running")
                    enableVideoRecordButton = true
                case .sessionStopped:
                    print("Camera session did stop running")
                    enableVideoRecordButton = false
                case .recordingBegun:
                    print("Did Begin Recording Video")
                case .recordingFinished:
                    print("Did finish Recording Video")
                    isVideoRecording = nil
                case let .processedMedia(media):
                    self.media = media
                    showPreview = true
                }
            }
            .store(in: &subscriptions)
    }
}
