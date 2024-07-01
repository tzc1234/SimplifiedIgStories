//
//  StoryCameraViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/03/2022.
//

import AVKit
import Combine

@MainActor final class StoryCameraViewModel: ObservableObject {
    @Published var flashMode: CameraFlashMode = .off
    
    @Published private(set) var enableVideoRecordBtn = false
    
    @Published var shouldPhotoTake = false {
        willSet {
            if newValue {
                camera.takePhoto(on: flashMode)
            }
        }
    }
    private(set) var lastTakenImage: UIImage?
    @Published var showPhotoPreview = false {
        didSet {
            if showPhotoPreview {
                camera.stopSession()
            } else {
                camera.startSession()
            }
        }
    }
    
    enum VideoRecordingStatus {
        case none, start, stop
    }
    @Published var videoRecordingStatus: VideoRecordingStatus = .none {
        willSet {
            switch newValue {
            case .none:
                break
            case .start:
                camera.startRecording()
            case .stop:
                camera.stopRecording()
            }
        }
    }
    private(set) var lastVideoURL: URL?
    @Published var showVideoPreview = false {
        didSet {
            if showVideoPreview {
                camera.stopSession()
            } else {
                camera.startSession()
            }
        }
    }
    
    @Published private(set) var isCamPermGranted = false
    @Published private(set) var isMicrophonePermGranted = false
    
    private var subscriptions = Set<AnyCancellable>()
    
    var videoPreviewTapPoint: CGPoint = .zero {
        didSet {
            camera.focus(on: videoPreviewTapPoint)
        }
    }
    
    var videoPreviewPinchFactor: CGFloat = .zero {
        didSet {
            camera.zoom(to: videoPreviewPinchFactor)
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

// MARK: computed variables
extension StoryCameraViewModel {
    var arePermissionsGranted: Bool {
        isCamPermGranted && isMicrophonePermGranted
    }
    
    var videoPreviewLayer: CALayer {
        camera.videoPreviewLayer
    }
}

// MARK: internal functions
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
}

// MARK: private functions
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
                    videoRecordingStatus = .none
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
