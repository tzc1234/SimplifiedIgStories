//
//  StoryCamViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/03/2022.
//

import AVFoundation
import AVKit
import Combine

@MainActor final class StoryCamViewModel: ObservableObject {
    @Published var flashMode: AVCaptureDevice.FlashMode = .off {
        willSet {
            camManager.flashMode = newValue
        }
    }
    
    @Published private(set) var enableVideoRecordBtn = false
    
    @Published var shouldPhotoTake = false {
        willSet {
            if newValue {
                camManager.takePhoto()
            }
        }
    }
    private(set) var lastTakenImage: UIImage?
    @Published var showPhotoPreview = false {
        didSet {
            if showPhotoPreview {
                camManager.stopSession()
            } else {
                camManager.startSession()
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
                camManager.startVideoRecording()
            case .stop:
                camManager.stopVideoRecording()
            }
        }
    }
    private(set) var lastVideoUrl: URL?
    @Published var showVideoPreview = false {
        didSet {
            if showVideoPreview {
                camManager.stopSession()
            } else {
                camManager.startSession()
            }
        }
    }
    
    @Published private(set) var isCamPermGranted = false
    @Published private(set) var isMicrophonePermGranted = false
    
    private var subscriptions = Set<AnyCancellable>()
    
    var videoPreviewTapPoint: CGPoint = .zero {
        didSet {
            camManager.focus(on: videoPreviewTapPoint)
        }
    }
    
    var videoPreviewPinchFactor: CGFloat = .zero {
        didSet {
            camManager.zoom(to: videoPreviewPinchFactor)
        }
    }
    
    private let camManager: CamManager
    private let cameraAuthorizationTracker: DeviceAuthorizationTracker
    private let microphoneAuthorizationTracker: DeviceAuthorizationTracker

    init(camManager: CamManager,
         cameraAuthorizationTracker: DeviceAuthorizationTracker = AVCaptureDeviceAuthorizationTracker(mediaType: .video),
         microphoneAuthorizationTracker: DeviceAuthorizationTracker = AVCaptureDeviceAuthorizationTracker(mediaType: .audio)) {
        self.camManager = camManager
        self.cameraAuthorizationTracker = cameraAuthorizationTracker
        self.microphoneAuthorizationTracker = microphoneAuthorizationTracker
        
        subscribeCamMangerPublishers()
    }
}

// MARK: computed variables
extension StoryCamViewModel {
    var arePermissionsGranted: Bool {
        isCamPermGranted && isMicrophonePermGranted
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        camManager.videoPreviewLayer
    }
}

// MARK: internal functions
extension StoryCamViewModel {
    func checkPermissions() {
        cameraAuthorizationTracker.startTracking()
        microphoneAuthorizationTracker.startTracking()
    }
    
    func setupAndStartSession() {
        camManager.setupAndStartSession()
    }
    
    func switchCamera() {
        camManager.switchCamera()
    }
}

// MARK: private functions
extension StoryCamViewModel {
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
        
        camManager.camStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] camStatus in
                switch camStatus {
                case .sessionStarted:
                    print("Camera session did start running")
                    self?.enableVideoRecordBtn = true
                case .sessionStopped:
                    print("Camera session did stop running")
                    self?.enableVideoRecordBtn = false
                case .photoTaken(photo: let photo):
                    self?.lastTakenImage = photo
                    self?.showPhotoPreview = true
                case .processingPhotoFailure:
                    break
                case .processingPhotoDataFailure:
                    break
                case .convertToUIImageFailure:
                    break
                case .recordingVideoBegun:
                    print("Did Begin Recording Video")
                case .recordingVideoFinished:
                    print("Did finish Recording Video")
                    self?.videoRecordingStatus = .none
                case .processingVideoFailure:
                    break
                case .processingVideoFinished(videoUrl: let videoUrl):
                    self?.lastVideoUrl = videoUrl
                    self?.showVideoPreview = true
                case .cameraSwitched(camPosition: _):
                    break
                }
            }
            .store(in: &subscriptions)
    }
}
