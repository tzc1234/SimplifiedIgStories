//
//  CaptureDeviceSpy.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 22/02/2024.
//

import AVFoundation

final class CaptureDeviceSpy: AVCaptureDevice {
    enum LockStatus {
        case locked
        case unlocked
    }
    
    private var _focusMode = FocusMode.locked
    private var _exposureMode = ExposureMode.locked
    private var _position = AVCaptureDevice.Position.unspecified
    private var _focusPointOfInterest = CGPoint.zero
    private var _exposurePointOfInterest = CGPoint.zero
    private var _videoZoomFactor: CGFloat = 0
    private(set) var loggedLockStatuses: [LockStatus]
    private var canChangeSettings: Bool {
        loggedLockStatuses.last == .locked
    }
    private var lockForConfigurationError: Error?
    private var loggedFocusModeSupported = [FocusMode]()
    private var loggedExposureModeSupported = [ExposureMode]()
    
    let mediaType: AVMediaType
    
    init(type: AVMediaType, position: AVCaptureDevice.Position) {
        self.mediaType = type
        self._position = position
        self.loggedLockStatuses = [LockStatus]()
        super.init(type: type)
    }
    
    init(type: AVMediaType, lockForConfigurationError: Error?) {
        self.mediaType = type
        self.loggedLockStatuses = [LockStatus]()
        self.lockForConfigurationError = lockForConfigurationError
        super.init(type: type)
    }
    
    override var focusMode: FocusMode {
        get { _focusMode }
        set {
            if canChangeSettings && loggedFocusModeSupported.contains(newValue) {
                _focusMode = newValue
            }
        }
    }
    
    override var focusPointOfInterest: CGPoint {
        get { _focusPointOfInterest }
        set { 
            if canChangeSettings {
                _focusPointOfInterest = newValue
            }
        }
    }
    
    override var exposureMode: ExposureMode {
        get { _exposureMode }
        set { 
            if canChangeSettings && loggedExposureModeSupported.contains(newValue) {
                _exposureMode = newValue
            }
        }
    }
    
    override var exposurePointOfInterest: CGPoint {
        get { _exposurePointOfInterest }
        set { 
            if canChangeSettings {
                _exposurePointOfInterest = newValue
            }
        }
    }
    
    override var position: AVCaptureDevice.Position {
        get { _position }
        set { 
            if canChangeSettings {
                _position = newValue
            }
        }
    }
    
    override var videoZoomFactor: CGFloat {
        get { _videoZoomFactor }
        set {
            if canChangeSettings {
                _videoZoomFactor = newValue
            }
        }
    }
    
    override var isFocusPointOfInterestSupported: Bool {
        true
    }
    
    override func isFocusModeSupported(_ focusMode: FocusMode) -> Bool {
        loggedFocusModeSupported.append(focusMode)
        return true
    }
    
    override var isExposurePointOfInterestSupported: Bool {
        true
    }
    
    override func isExposureModeSupported(_ exposureMode: ExposureMode) -> Bool {
        loggedExposureModeSupported.append(exposureMode)
        return true
    }
    
    override func lockForConfiguration() throws {
        try super.lockForConfiguration()
        
        if let error = lockForConfigurationError {
            throw error
        }
        
        loggedLockStatuses.append(.locked)
    }
    
    override func unlockForConfiguration() {
        super.unlockForConfiguration()
        
        loggedLockStatuses.append(.unlocked)
    }
}
