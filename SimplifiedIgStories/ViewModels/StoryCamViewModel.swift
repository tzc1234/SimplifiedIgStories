//
//  StoryCamViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/03/2022.
//

import AVFoundation
import AVKit
import Combine

@MainActor
final class StoryCamViewModel: ObservableObject {
    @Published var camPosition: AVCaptureDevice.Position = .back {
        willSet {
            camManager.camPosition = newValue
            camManager.switchCamera()
        }
    }
    
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
    @Published var photoDidTake = false
    
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
    @Published var videoDidRecord = false
    
    @Published private(set) var isCamPermGranted = false
    @Published private(set) var isMicrophonePermGranted = false
    
    private var subscriptions = Set<AnyCancellable>()
    
    private var camManager: CamManager

    init(camManager: CamManager) {
        self.camManager = camManager
        subscribeCamMangerPublishers()
    }
}

// MARK: enums
extension StoryCamViewModel {
    enum VideoRecordingStatus {
        case none, start, stop
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
        camManager.checkPermissions()
    }
    
    func setupSession() {
        camManager.setupSession()
    }
}

// MARK: private functions
extension StoryCamViewModel {
    private func subscribeCamMangerPublishers() {
        camManager.camPermPublisher
            .sink { [weak self] isGranted in
                self?.isCamPermGranted = isGranted
            }
            .store(in: &subscriptions)
        
        camManager.microphonePermPublisher
            .sink { [weak self] isGranted in
                self?.isMicrophonePermGranted = isGranted
            }
            .store(in: &subscriptions)
        
        camManager.camStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] camStatus in
                guard let self = self else { return }
                
                switch camStatus {
                case .sessionStarted:
                    print("Camera session did start running")
                    self.enableVideoRecordBtn = true
                case .sessionStopped:
                    print("Camera session did stop running")
                    self.enableVideoRecordBtn = false
                case .photoTaken(photo: let photo):
                    self.lastTakenImage = photo
                    self.photoDidTake = true
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
                    self.videoRecordingStatus = .none
                case .processingVideoFailure:
                    break
                case .processingVideoFinished(videoUrl: let videoUrl):
                    self.lastVideoUrl = videoUrl
                    self.videoDidRecord = true
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }
}
