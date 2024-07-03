//
//  CameraSpy.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 03/07/2024.
//

import UIKit
import Combine
@testable import Simple_IG_Story

final class CameraSpy: Camera {
    private let statusPublisher = PassthroughSubject<CameraStatus, Never>()
    private(set) var startSessionCallCount = 0
    private(set) var stopSessionCallCount = 0
    private(set) var startRecordingCallCount = 0
    private(set) var stopRecordingCallCount = 0
    private(set) var switchCameraCallCount = 0
    private(set) var loggedFlashModes = [CameraFlashMode]()
    private(set) var loggedFocusPoints = [CGPoint]()
    private(set) var loggedZoomFactors = [CGFloat]()
    
    let cameraPosition = CameraPosition.back
    
    private let videoPreviewLayerStub: CALayer
    
    init(videoPreviewLayerStub: CALayer = CALayer()) {
        self.videoPreviewLayerStub = videoPreviewLayerStub
    }
    
    var videoPreviewLayer: CALayer {
        videoPreviewLayerStub
    }
    
    func publish(status: CameraStatus) {
        statusPublisher.send(status)
    }
    
    func getStatusPublisher() -> AnyPublisher<CameraStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
    
    func startSession() {
        startSessionCallCount += 1
    }
    
    func stopSession() {
        stopSessionCallCount += 1
    }
    
    func switchCamera() {
        switchCameraCallCount += 1
    }
    
    func takePhoto(on flashMode: CameraFlashMode) {
        loggedFlashModes.append(flashMode)
    }
    
    func startRecording() {
        startRecordingCallCount += 1
    }
    
    func stopRecording() {
        stopRecordingCallCount += 1
    }
    
    func focus(on point: CGPoint) {
        loggedFocusPoints.append(point)
    }
    
    func zoom(to factor: CGFloat) {
        loggedZoomFactors.append(factor)
    }
}
