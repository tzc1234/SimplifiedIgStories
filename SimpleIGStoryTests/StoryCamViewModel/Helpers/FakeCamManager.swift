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
    private(set) var setupAndStartSessionCalled = false
    private(set) var startSessionCalled = false
    private(set) var stopSessionCalled = false
    private(set) var switchCameraCalled = false
    private(set) var takePhotoCalled = false
    private(set) var lastPhoto: UIImage?
    private(set) var startVideoRecordingCalled = false
    private(set) var stopVideoRecordingCalled = false
    private(set) var lastVideoUrl: URL?
    private(set) var focusPoint: CGPoint?
    private(set) var zoomFactor: CGFloat?
}

// MARK: - internal functions
extension FakeCamManager {
    func setupAndStartSession() {
        setupAndStartSessionCalled.toggle()
        camStatusPublisher.send(.sessionStarted)
    }
    
    func startSession() {
        startSessionCalled.toggle()
        camStatusPublisher.send(.sessionStarted)
    }
    
    func stopSession() {
        stopSessionCalled.toggle()
        camStatusPublisher.send(.sessionStopped)
    }
    
    func switchCamera() {
        switchCameraCalled.toggle()
        camPosition = camPosition == .back ? .front : .back
        camStatusPublisher.send(.cameraSwitched(camPosition: camPosition))
    }
    
    func takePhoto() {
        takePhotoCalled.toggle()
        lastPhoto = UIImage()
        camStatusPublisher.send(.photoTaken(photo: lastPhoto!))
    }
    
    func startVideoRecording() {
        startVideoRecordingCalled.toggle()
        camStatusPublisher.send(.recordingVideoBegun)
    }
    
    func stopVideoRecording() {
        stopVideoRecordingCalled.toggle()
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
