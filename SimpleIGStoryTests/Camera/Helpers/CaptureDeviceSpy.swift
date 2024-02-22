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
    private(set) var loggedLockStatuses: [LockStatus]
    private var canChangeSettings: Bool {
        loggedLockStatuses.last == .locked
    }
    private var shouldLockForConfigurationThrow: Bool
    
    let mediaType: AVMediaType
    
    init(type: AVMediaType, position: AVCaptureDevice.Position) {
        self.mediaType = type
        self._position = position
        self.loggedLockStatuses = [LockStatus]()
        self.shouldLockForConfigurationThrow = false
        super.init(type: type)
    }
    
    init(type: AVMediaType, shouldLockForConfigurationThrow: Bool) {
        self.mediaType = type
        self.loggedLockStatuses = [LockStatus]()
        self.shouldLockForConfigurationThrow = shouldLockForConfigurationThrow
        super.init(type: type)
    }
    
    override var focusMode: FocusMode {
        get { _focusMode }
        set {
            if canChangeSettings {
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
            if canChangeSettings {
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
    
    override var isFocusPointOfInterestSupported: Bool {
        true
    }
    
    override func isFocusModeSupported(_ focusMode: FocusMode) -> Bool {
        true
    }
    
    override var isExposurePointOfInterestSupported: Bool {
        true
    }
    
    override func isExposureModeSupported(_ exposureMode: ExposureMode) -> Bool {
        true
    }
    
    override func lockForConfiguration() throws {
        try super.lockForConfiguration()
        
        if shouldLockForConfigurationThrow {
            throw anyNSError()
        }
        
        loggedLockStatuses.append(.locked)
    }
    
    override func unlockForConfiguration() {
        super.unlockForConfiguration()
        
        loggedLockStatuses.append(.unlocked)
    }
}
