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

final class MockCamManager: Camera {
    private let camStatusPublisher = PassthroughSubject<CameraStatus, Never>()
    
    var cameraPosition: CameraPosition = .back
    
    lazy var videoPreviewLayer: CALayer = {
        AVCaptureVideoPreviewLayer()
    }()
    
    // Additional variables for testings.
    private(set) var startSessionCallCount = 0
    private(set) var stopSessionCallCount = 0
    private(set) var switchCameraCallCount = 0
    private(set) var startVideoRecordingCallCount = 0
    private(set) var stopVideoRecordingCallCount = 0
    private(set) var lastVideoUrl: URL?
    private(set) var focusPoint: CGPoint?
    private(set) var zoomFactor: CGFloat?
}

// MARK: internal functions
extension MockCamManager {
    func getStatusPublisher() -> AnyPublisher<CameraStatus, Never> {
        camStatusPublisher.eraseToAnyPublisher()
    }
    
    func startSession() {
        startSessionCallCount += 1
        camStatusPublisher.send(.sessionStarted)
    }
    
    func stopSession() {
        stopSessionCallCount += 1
        camStatusPublisher.send(.sessionStopped)
    }
    
    func switchCamera() {
        switchCameraCallCount += 1
        cameraPosition = cameraPosition == .back ? .front : .back
        camStatusPublisher.send(.cameraSwitched(camPosition: cameraPosition))
    }
    
    func startVideoRecording() {
        startVideoRecordingCallCount += 1
        camStatusPublisher.send(.recordingVideoBegun)
    }
    
    func stopVideoRecording() {
        stopVideoRecordingCallCount += 1
        camStatusPublisher.send(.recordingVideoFinished)
    }
    
    func finishVideoProcessing() {
        lastVideoUrl = URL(string: "videoURL")
        camStatusPublisher.send(.processingVideoFinished(videoUrl: lastVideoUrl!))
    }
    
    func focus(on point: CGPoint) {
        focusPoint = point
    }
    
    func zoom(to factor: CGFloat) {
        zoomFactor = factor
    }
}
