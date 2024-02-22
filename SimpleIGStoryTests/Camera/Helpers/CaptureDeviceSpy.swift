//
//  CaptureDeviceSpy.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 22/02/2024.
//

import AVFoundation

final class CaptureDeviceSpy: AVCaptureDevice {
    private var _focusMode = FocusMode.locked
    private var _exposureMode = ExposureMode.locked
    private var _position = AVCaptureDevice.Position.unspecified
    private var _focusPointOfInterest = CGPoint.zero
    
    let mediaType: AVMediaType
    
    init(type: AVMediaType, position: AVCaptureDevice.Position) {
        self.mediaType = type
        self._position = position
        super.init(type: type)
    }
    
    override var focusMode: FocusMode {
        get { _focusMode }
        set { _focusMode = newValue }
    }
    
    override var focusPointOfInterest: CGPoint {
        get { _focusPointOfInterest }
        set { _focusPointOfInterest = newValue }
    }
    
    override var exposureMode: ExposureMode {
        get { _exposureMode }
        set { _exposureMode = newValue }
    }
    
    override var position: AVCaptureDevice.Position {
        get { _position }
        set { _position = newValue }
    }
    
    override var isFocusPointOfInterestSupported: Bool {
        true
    }
    
    override func isFocusModeSupported(_ focusMode: FocusMode) -> Bool {
        true
    }
    
    override func isExposureModeSupported(_ exposureMode: ExposureMode) -> Bool {
        true
    }
}
