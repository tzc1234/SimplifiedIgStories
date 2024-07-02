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
    
    @Published var flashMode = CameraFlashMode.off
    @Published private(set) var enableVideoRecordBtn = false
    
    private(set) var lastTakenImage: UIImage?
    private(set) var lastVideoURL: URL?
    
    @Published private(set) var isCamPermGranted = false
    @Published private(set) var isMicrophonePermGranted = false
    
    @Published var showPhotoPreview = false {
        didSet {
            showPhotoPreview ? camera.stopSession() : camera.startSession()
        }
    }
    
    @Published var showVideoPreview = false {
        didSet {
            showVideoPreview ? camera.stopSession() : camera.startSession()
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
         cameraAuthorizationTracker: DeviceAuthorizationTracker = AVCaptureDeviceAuthorizationTracker(mediaType: .video),
         microphoneAuthorizationTracker: DeviceAuthorizationTracker = AVCaptureDeviceAuthorizationTracker(mediaType: .audio)) {
        self.camera = camera
        self.cameraAuthorizationTracker = cameraAuthorizationTracker
        self.microphoneAuthorizationTracker = microphoneAuthorizationTracker
        self.subscribeCamMangerPublishers()
    }
}

extension StoryCameraViewModel {
    var arePermissionsGranted: Bool {
        isCamPermGranted && isMicrophonePermGranted
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
    
    func startSession() {
        camera.startSession()
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isGranted in
                self?.isCamPermGranted = isGranted
            }
            .store(in: &subscriptions)
        
        microphoneAuthorizationTracker
            .getPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isGranted in
                self?.isMicrophonePermGranted = isGranted
            }
            .store(in: &subscriptions)
        
        camera
            .getStatusPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] camStatus in
                guard let self else { return }
                
                switch camStatus {
                case .sessionStarted:
                    print("Camera session did start running")
                    enableVideoRecordBtn = true
                case .sessionStopped:
                    print("Camera session did stop running")
                    enableVideoRecordBtn = false
                case .cameraSwitched:
                    break
                case .addPhotoOutputFailure:
                    break
                case .photoTaken(let photo):
                    lastTakenImage = photo
                    showPhotoPreview = true
                case .imageConvertingFailure:
                    break
                case .recordingBegun:
                    print("Did Begin Recording Video")
                case .recordingFinished:
                    print("Did finish Recording Video")
                    isVideoRecording = nil
                case .videoProcessFailure:
                    break
                case .processedVideo(let videoURL):
                    lastVideoURL = videoURL
                    showVideoPreview = true
                case .addMovieFileOutputFailure:
                    break
                }
            }
            .store(in: &subscriptions)
    }
}
