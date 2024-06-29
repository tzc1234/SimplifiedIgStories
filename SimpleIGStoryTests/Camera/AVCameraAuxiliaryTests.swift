//
//  AVCameraAuxiliaryTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 22/02/2024.
//

import XCTest
import AVFoundation
@testable import Simple_IG_Story

final class AVCameraAuxiliaryTests: XCTestCase {
    func test_init_doesNotDeliverStatusUponInit() {
        let (sut, _) = makeSUT()
        let statusSpy = CameraAuxiliaryStatusSpy(publisher: sut.getStatusPublisher())
        
        XCTAssertTrue(statusSpy.loggedStatuses.isEmpty)
    }
    
    func test_focus_deliversCaptureDeviceNotFoundStatusWhenNoCaptureDeviceFound() {
        let (sut, _) = makeSUT(isCaptureDeviceExisted: false)
        let statusSpy = CameraAuxiliaryStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.focus(on: .zero)
        
        XCTAssertEqual(statusSpy.loggedStatuses, [.captureDeviceNotFound])
    }
    
    func test_focus_setsFocusProperly() {
        let (sut, device) = makeSUT()
        let initialFocusPoint = device.focusPointOfInterest
        
        sut.focus(on: .init(x: 999, y: 999))
        
        XCTAssertNotEqual(device.focusPointOfInterest, initialFocusPoint)
        XCTAssertEqual(device.focusMode, .autoFocus)
        XCTAssertEqual(device.loggedLockStatuses, [.locked, .unlocked])
    }
    
    func test_focus_setsExposureProperly() {
        let (sut, device) = makeSUT()
        let initialExposurePoint = device.exposurePointOfInterest
        
        sut.focus(on: .init(x: 999, y: 999))
        
        XCTAssertNotEqual(device.exposurePointOfInterest, initialExposurePoint)
        XCTAssertEqual(device.exposureMode, .continuousAutoExposure)
        XCTAssertEqual(device.loggedLockStatuses, [.locked, .unlocked])
    }
    
    func test_focus_deliversChangeDeviceSettingsFailureStatusWhenLockForConfigurationErrorOccurred() {
        let (sut, _) = makeSUT(lockForConfigurationError: anyNSError())
        let statusSpy = CameraAuxiliaryStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.focus(on: .zero)
        
        XCTAssertEqual(statusSpy.loggedStatuses, [.changeDeviceSettingsFailure])
    }
    
    func test_zoom_setsZoomFactorProperly() {
        let (sut, device) = makeSUT()
        let initialZoomFactor = device.videoZoomFactor
        
        sut.zoom(to: 999)
        
        XCTAssertNotEqual(device.videoZoomFactor, initialZoomFactor)
    }
    
    func test_zoom_deliversChangeDeviceSettingsFailureStatusWhenLockForConfigurationErrorOccurred() {
        let (sut, _) = makeSUT(lockForConfigurationError: anyNSError())
        let statusSpy = CameraAuxiliaryStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.zoom(to: 999)
        
        XCTAssertEqual(statusSpy.loggedStatuses, [.changeDeviceSettingsFailure])
    }
    
    // MARK: - Helpers
    
    private typealias CameraAuxiliaryStatusSpy = StatusSpy<CameraAuxiliaryStatus>
    
    private func makeSUT(isCaptureDeviceExisted: Bool = true,
                         lockForConfigurationError: Error? = nil,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: AVCameraAuxiliary, captureDevice: CaptureDeviceSpy) {
        AVCaptureDevice.swizzled()
        let captureDevice = CaptureDeviceSpy(type: .video, lockForConfigurationError: lockForConfigurationError)
        let camera = AuxiliarySupportedCameraSpy(
            captureDevice: isCaptureDeviceExisted ? captureDevice : nil,
            performOnSessionQueue: { $0() }
        )
        let sut = AVCameraAuxiliary(camera: camera)
        addTeardownBlock { AVCaptureDevice.revertSwizzled() }
        trackForMemoryLeaks(camera, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, captureDevice)
    }
    
    private final class AuxiliarySupportedCameraSpy: AuxiliarySupportedCamera {
        let captureDevice: AVCaptureDevice?
        let performOnSessionQueue: (@escaping () -> Void) -> Void
        
        init(captureDevice: AVCaptureDevice?, performOnSessionQueue: @escaping (@escaping () -> Void) -> Void) {
            self.captureDevice = captureDevice
            self.performOnSessionQueue = performOnSessionQueue
        }
    }
}
