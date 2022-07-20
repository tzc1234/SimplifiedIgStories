//
//  FakeCamManager.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/07/2022.
//

import AVFoundation
import Combine
import UIKit
@testable import Simple_IG_Story

final class FakeCamManager: CamManager {
    var camPermPublisher = CurrentValueSubject<Bool, Never>(false)
    var microphonePermPublisher = CurrentValueSubject<Bool, Never>(false)
    var camStatusPublisher = PassthroughSubject<CamStatus, Never>()
    
    var camPosition: AVCaptureDevice.Position = .back
    var flashMode: AVCaptureDevice.FlashMode = .off
    
    lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = {
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

// MARK: - internal functions
extension FakeCamManager {
    func setupAndStartSession() {
        setupAndStartSessionCallCount += 1
        camStatusPublisher.send(.sessionStarted)
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
        camPosition = camPosition == .back ? .front : .back
        camStatusPublisher.send(.cameraSwitched(camPosition: camPosition))
    }
    
    func takePhoto() {
        takePhotoCallCount += 1
        lastPhoto = UIImage()
        camStatusPublisher.send(.photoTaken(photo: lastPhoto!))
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
        lastVideoUrl = URL(string: "videoUrl")
        camStatusPublisher.send(.processingVideoFinished(videoUrl: lastVideoUrl!))
    }
    
    func checkPermissions() {
        camPermPublisher.send(true)
        microphonePermPublisher.send(true)
    }
    
    func focus(on point: CGPoint) {
        focusPoint = point
    }
    
    func zoom(to factor: CGFloat) {
        zoomFactor = factor
    }
}
