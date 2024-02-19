//
//  CaptureSessionSpy.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 19/02/2024.
//

import AVFoundation
@testable import Simple_IG_Story

final class CaptureSessionSpy: AVCaptureSession {
    enum ConfigurationStatus {
        case begin
        case commit
    }
    
    private(set) var loggedConfigurationStatus = [ConfigurationStatus]()
    private(set) var loggedInputs = [AVCaptureInput]()
    private(set) var loggedOutputs = [AVCaptureOutput]()
    
    var loggedPhotoOutputs: [AVCapturePhotoOutput] {
        loggedOutputs.compactMap { $0 as? AVCapturePhotoOutput }
    }
    
    private var _isRunning = false
    private var canAddOutput: Bool
    
    init(isRunning: Bool, canAddOutput: Bool) {
        self._isRunning = isRunning
        self.canAddOutput = canAddOutput
    }
    
    override var isRunning: Bool {
        _isRunning
    }
    
    override func canAddInput(_ input: AVCaptureInput) -> Bool {
        true
    }
    
    override func addInput(_ input: AVCaptureInput) {
        if isRunning, loggedConfigurationStatus.last != .begin {
            return
        }
        
        loggedInputs.append(input)
    }
    
    override func canAddOutput(_ output: AVCaptureOutput) -> Bool {
        canAddOutput
    }
    
    override func addOutput(_ output: AVCaptureOutput) {
        if isRunning, loggedConfigurationStatus.last != .begin {
            return
        }
        
        loggedOutputs.append(output)
    }
    
    override func startRunning() {
        _isRunning = true
        NotificationCenter.default.post(name: .AVCaptureSessionDidStartRunning, object: nil)
    }
    
    override func stopRunning() {
        _isRunning = false
        NotificationCenter.default.post(name: .AVCaptureSessionDidStopRunning, object: nil)
    }
    
    override func beginConfiguration() {
        super.beginConfiguration()
        
        loggedConfigurationStatus.append(.begin)
    }
    
    override func commitConfiguration() {
        super.commitConfiguration()
        
        loggedConfigurationStatus.append(.commit)
    }
    
    func resetLoggedInputs() {
        loggedInputs.removeAll()
    }
}
