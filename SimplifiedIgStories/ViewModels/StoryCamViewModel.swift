//
//  StoryCamViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/03/2022.
//

import AVFoundation
import AVKit
import Combine
import SwiftyCam
import SwiftUI

@MainActor
final class StoryCamViewModel: ObservableObject {
    @Published var camPosition: AVCaptureDevice.Position = .back {
        willSet {
            camManager.camPosition = newValue
        }
    }
    
    @Published private(set) var enableVideoRecordBtn = false
    @Published var flashMode: FlashMode = .off
    
    @Published var shouldPhotoTake = false
    private(set) var lastTakenImage: UIImage?
    @Published var photoDidTake = false
    
    @Published var videoRecordingStatus: VideoRecordingStatus = .none
    private(set) var lastVideoUrl: URL?
    @Published var videoDidRecord = false
    
    @Published private(set) var isCamPermGranted = false
    @Published private(set) var isMicrophonePermGranted = false
    
    private var subscriptions = Set<AnyCancellable>()
    
    private var camManager: CamManager

    init(camManager: CamManager) {
        self.camManager = camManager
        
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
    }
}

// MARK: enums
extension StoryCamViewModel {
    enum FlashMode {
        case on, off, auto
        
        var swiftyCamFlashMode: SwiftyCamViewController.FlashMode {
            switch self {
            case .auto: return .auto
            case .on: return .on
            case .off: return .off
            }
        }
        
        var systemImageName: String {
            switch self {
            case .auto: return "bolt.badge.a.fill"
            case .on: return "bolt.fill"
            case .off: return  "bolt.slash.fill"
            }
        }
    }
    
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
    
    var session: AVCaptureSession {
        camManager.session
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
    
//    func subscribe(to publisher: AnyPublisher<SwiftyCamStatus, Never>) {
//        publisher
//            .receive(on: DispatchQueue.main)
//            .sink(receiveValue: { [weak self] swiftyCamStatus in
//                guard let self = self else { return }
//
//                switch swiftyCamStatus {
//                case .sessionStarted:
//                    print("Camera session did start running")
//                    self.enableVideoRecordBtn = true
//                case .sessionStopped:
//                    print("Camera session did stop running")
//                    self.enableVideoRecordBtn = false
//                case .photoTaken(photo: let photo):
//                    self.lastTakenImage = photo
//                    self.photoDidTake = true
//                case .recordingVideoBegun:
//                    print("Did Begin Recording Video")
//                case .recordingVideoFinished:
//                    print("Did finish Recording Video")
//                    self.videoRecordingStatus = .none
//                case .processingVideoFinished(videoUrl: let videoUrl):
//                    self.lastVideoUrl = videoUrl
//                    self.videoDidRecord = true
//                default:
//                    break
//                }
//            })
//            .store(in: &subscriptions)
//    }
}
