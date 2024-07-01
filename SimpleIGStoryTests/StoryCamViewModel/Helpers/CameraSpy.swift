//
//  CameraSpy.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/07/2022.
//

import AVFoundation
import Combine
import UIKit
@testable import Simple_IG_Story

final class CameraSpy: CameraCore {
    private let camStatusPublisher = PassthroughSubject<CameraCoreStatus, Never>()
    
    var cameraPosition: CameraPosition = .back
    
    lazy var videoPreviewLayer: CALayer = {
        AVCaptureVideoPreviewLayer()
    }()
    
    // Additional variables for testings.
    private(set) var startSessionCallCount = 0
    private(set) var stopSessionCallCount = 0
    private(set) var switchCameraCallCount = 0
}

// MARK: internal functions
extension CameraSpy {
    func getStatusPublisher() -> AnyPublisher<CameraCoreStatus, Never> {
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
        camStatusPublisher.send(.cameraSwitched(position: cameraPosition))
    }
}
