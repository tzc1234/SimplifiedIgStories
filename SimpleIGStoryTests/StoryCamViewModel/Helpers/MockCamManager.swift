//
//  MockCamManager.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/07/2022.
//

import AVFoundation
import Combine
import UIKit
@testable import Simple_IG_Story

final class MockCamManager: CamManager {
    private let _camStatusPublisher = PassthroughSubject<CamStatus, Never>()
    var camStatusPublisher: AnyPublisher<CamStatus, Never> {
        _camStatusPublisher.eraseToAnyPublisher()
    }
    
    var cameraPosition: CameraPosition = .back
    var flashMode: CameraFlashMode = .off
    
    lazy var videoPreviewLayer: CALayer = {
        AVCaptureVideoPreviewLayer()
    }()
    
    // Additional variables for testings.
    private(set) var setupAndStartSessionCallCount = 0
    private(set) var startSessionCallCount = 0
    private(set) var stopSessionCallCount = 0
    private(set) var switchCameraCallCount = 0
    private(set) var takePhotoCallCount = 0
    private(set) var lastPhoto: UIImage?
    private(set) var startVideoRecordingCallCount = 0
    private(set) var stopVideoRecordingCallCount = 0
    private(set) var lastVideoUrl: URL?
    private(set) var focusPoint: CGPoint?
    private(set) var zoomFactor: CGFloat?
}

// MARK: internal functions
extension MockCamManager {
    func setupAndStartSession() {
        setupAndStartSessionCallCount += 1
        _camStatusPublisher.send(.sessionStarted)
    }
    
    func startSession() {
        startSessionCallCount += 1
        _camStatusPublisher.send(.sessionStarted)
    }
    
    func stopSession() {
        stopSessionCallCount += 1
        _camStatusPublisher.send(.sessionStopped)
    }
    
    func switchCamera() {
        switchCameraCallCount += 1
        cameraPosition = cameraPosition == .back ? .front : .back
        _camStatusPublisher.send(.cameraSwitched(camPosition: cameraPosition))
    }
    
    func takePhoto() {
        takePhotoCallCount += 1
        lastPhoto = UIImage()
        _camStatusPublisher.send(.photoTaken(photo: lastPhoto!))
    }
    
    func startVideoRecording() {
        startVideoRecordingCallCount += 1
        _camStatusPublisher.send(.recordingVideoBegun)
    }
    
    func stopVideoRecording() {
        stopVideoRecordingCallCount += 1
        _camStatusPublisher.send(.recordingVideoFinished)
    }
    
    func finishVideoProcessing() {
        lastVideoUrl = URL(string: "videoURL")
        _camStatusPublisher.send(.processingVideoFinished(videoUrl: lastVideoUrl!))
    }
    
    func focus(on point: CGPoint) {
        focusPoint = point
    }
    
    func zoom(to factor: CGFloat) {
        zoomFactor = factor
    }
}
