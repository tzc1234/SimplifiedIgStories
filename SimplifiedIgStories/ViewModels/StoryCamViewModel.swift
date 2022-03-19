//
//  StoryCamViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/03/2022.
//

import Foundation
import SwiftUI
import AVKit
import Combine

final class StoryCamViewModel: ObservableObject {
    @Published var cameraSelection: SwiftyCamViewController.CameraSelection = .rear
    @Published var enableVideoRecordBtn = false
    @Published var flashMode: FlashMode = .off
    
    @Published var shouldPhotoTake = false
    var lastTakenImage: UIImage?
    @Published var photoDidTake = false
    
    @Published var videoRecordingStatus: VideoRecordingStatus = .none
    var lastVideoUrl: URL?
    @Published var videoDidRecord = false
    
    @Published var camPermGranted = false
    @Published var microphonePermGranted = false
    
    private var subscription: AnyCancellable?
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

// MARK: functions
extension StoryCamViewModel {
    private func checkCameraPermission() {
        let camPermStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch camPermStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { isGranted in
                DispatchQueue.main.async { [weak self] in
                    self?.camPermGranted = isGranted
                }
            }
        case .restricted:
            // nothing can do
            break
        case .denied:
            camPermGranted = false
        case .authorized:
            camPermGranted = true
        @unknown default:
            break
        }
    }
    
    private func checkMicrophonePermission() {
        let microphonePermStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        switch microphonePermStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { isGranted in
                DispatchQueue.main.async { [weak self] in
                    self?.microphonePermGranted = isGranted
                }
            }
        case .restricted:
            // nothing can do
            break
        case .denied:
            microphonePermGranted = false
        case .authorized:
            microphonePermGranted = true
        @unknown default:
            break
        }
    }
    
    func requestPermission() {
        checkCameraPermission()
        checkMicrophonePermission()
    }
    
    func subscribe(to publisher: AnyPublisher<SwiftyCamStatus, Never>) {
        subscription = publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] swiftyCamStatus in
                guard let self = self else { return }
                
                switch swiftyCamStatus {
                case .sessionStarted:
                    print("Camera session did start running")
                    self.enableVideoRecordBtn = true
                case .sessionStopped:
                    print("Camera session did stop running")
                    self.enableVideoRecordBtn = false
                case .photoTaken(photo: let photo):
                    self.lastTakenImage = photo
                    self.photoDidTake = true
                case .recordingVideoBegun:
                    print("Did Begin Recording Video")
                case .recordingVideoFinished:
                    print("Did finish Recording Video")
                    self.videoRecordingStatus = .none
                case .processingVideoFinished(videoUrl: let videoUrl):
                    self.lastVideoUrl = videoUrl
                    self.videoDidRecord = true
                default:
                    break
                }
            })
    }
}
