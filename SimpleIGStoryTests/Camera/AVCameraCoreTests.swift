//
//  AVCameraCoreTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 14/02/2024.
//

import XCTest
import AVFoundation
@testable import Simple_IG_Story

final class AVCameraCoreTests: XCTestCase {
    func test_init_doesNotDeliverAnyStatusUponInit() {
        let (sut, _) = makeSUT()
        let spy = CameraStatusSpy(publisher: sut.getStatusPublisher())
        
        XCTAssertEqual(spy.loggedStatuses, [])
    }
    
    func test_videoPreviewLayer_deliversPreviewLayerProperly() {
        let (sut, _) = makeSUT()
        
        let previewLayer = sut.videoPreviewLayer as? AVCaptureVideoPreviewLayer
        
        XCTAssertNotNil(previewLayer)
    }
    
    func test_startSession_ensuresInputsAreAddedToSessionProperlyWhenSessionIsNotRunning() {
        let exp = expectation(description: "Wait for session queue")
        let captureDevicesSpy = CaptureDevicesSpy()
        let (sut, session) = makeSUT(
            isSessionRunning: false,
            captureDevicesSpy: captureDevicesSpy,
            afterPerformOnSessionQueue: { exp.fulfill() }
        )
        
        sut.startSession()
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(session.loggedInputs.count, 2)
        XCTAssertEqual(captureDevicesSpy.loggedDeviceTypes, [.video, .audio])
    }
    
    func test_startSession_doesNotAddInputsWhenSessionIsRunning() {
        let exp = expectation(description: "Wait for session queue")
        let (sut, session) = makeSUT(
            isSessionRunning: true,
            afterPerformOnSessionQueue: { exp.fulfill() }
        )
        
        sut.startSession()
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(session.loggedInputs, [])
    }
    
    func test_startSession_ensuresVideoDeviceSettingsCorrectWhenSessionIsNotRunning() {
        let exp = expectation(description: "Wait for session queue")
        let captureDevicesSpy = CaptureDevicesSpy()
        let (sut, _) = makeSUT(
            isSessionRunning: false,
            captureDevicesSpy: captureDevicesSpy,
            afterPerformOnSessionQueue: { exp.fulfill() }
        )
        
        sut.startSession()
        wait(for: [exp], timeout: 1)
        
        assertVideoDeviceSettings(in: captureDevicesSpy.loggedDevices, withExpectedPosition: sut.cameraPosition)
    }
    
    func test_startSession_deliversSessionStartedStatusAfterStartSession() {
        let exp = expectation(description: "Wait for session queue")
        let (sut, _) = makeSUT(afterPerformOnSessionQueue: { exp.fulfill() })
        
        expect(sut, deliverStatuses: [.sessionStarted], when: {
            sut.startSession()
        })
        wait(for: [exp], timeout: 1)
    }
    
    func test_stopSession_deliversSessionStoppedStatusAfterStopSession() {
        let exp = expectation(description: "Wait for session queue")
        let (sut, _) = makeSUT(afterPerformOnSessionQueue: { exp.fulfill() })
        
        expect(sut, deliverStatuses: [.sessionStarted, .sessionStopped], when: {
            sut.startSession()
            sut.stopSession()
        })
        wait(for: [exp], timeout: 1)
    }
    
    func test_switchCamera_switchesCameraPosition() {
        let exp = expectation(description: "Wait for session queue twice")
        exp.expectedFulfillmentCount = 2
        let captureDevicesSpy = CaptureDevicesSpy()
        let (sut, _) = makeSUT(captureDevicesSpy: captureDevicesSpy, afterPerformOnSessionQueue: { exp.fulfill() })
        let initialPosition = sut.cameraPosition
        
        sut.startSession()
        sut.switchCamera()
        wait(for: [exp], timeout: 1)
        
        assertVideoDeviceSettings(in: captureDevicesSpy.loggedDevices, withExpectedPosition: initialPosition.toggle())
    }
    
    func test_switchCamera_reAddsInputsToSession() {
        let exp = expectation(description: "Wait for session queue twice")
        exp.expectedFulfillmentCount = 2
        let captureDevicesSpy = CaptureDevicesSpy()
        let (sut, session) = makeSUT(
            captureDevicesSpy: captureDevicesSpy,
            afterPerformOnSessionQueue: { exp.fulfill() }
        )
        
        sut.startSession()
        session.resetLoggedInputs()
        captureDevicesSpy.resetLoggings()
        sut.switchCamera()
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(session.loggedInputs.count, 2)
        XCTAssertEqual(session.loggedConfigurationStatus, [.begin, .commit])
        XCTAssertEqual(captureDevicesSpy.loggedDeviceTypes, [.video, .audio])
    }
    
    func test_switchCamera_deliversCameraSwitchedStatus() {
        let exp = expectation(description: "Wait for session queue")
        let (sut, _) = makeSUT(afterPerformOnSessionQueue: { exp.fulfill() })
        let initialPosition = sut.cameraPosition
        
        expect(sut, deliverStatuses: [.cameraSwitched(position: initialPosition.toggle())], when: {
            sut.switchCamera()
        })
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: - Helpers
    
    private typealias CameraStatusSpy = StatusSpy<CameraCoreStatus>
    
    private func makeSUT(isSessionRunning: Bool = false,
                         captureDevicesSpy: CaptureDevicesSpy? = nil,
                         afterPerformOnSessionQueue: @escaping () -> Void = {})
    -> (sut: AVCameraCore, session: CaptureSessionSpy) {
        AVCaptureDevice.swizzled()
        let session = CaptureSessionSpy(isRunning: isSessionRunning, canAddOutput: false)
        let captureDevicesSpy = captureDevicesSpy ?? CaptureDevicesSpy()
        let sut = AVCameraCore(
            session: session,
            makeCaptureDeviceInput: captureDevicesSpy.makeCaptureInput,
            performOnSessionQueue: { action in
                action()
                afterPerformOnSessionQueue()
            }
        )
        addTeardownBlock { AVCaptureDevice.revertSwizzled() }
        return (sut, session)
    }
    
    private func assertVideoDeviceSettings(in devices: [AVCaptureDevice],
                                           withExpectedPosition position: CameraPosition,
                                           file: StaticString = #filePath,
                                           line: UInt = #line) {
        let videoDevice = devices.last(where: { $0.type == .video })
        XCTAssertEqual(videoDevice?.focusMode, .continuousAutoFocus, file: file, line: line)
        XCTAssertEqual(videoDevice?.exposureMode, .continuousAutoExposure, file: file, line: line)
        XCTAssertEqual(videoDevice?.position, position.toCaptureDevicePosition(), file: file, line: line)
    }
    
    private func expect(_ sut: AVCameraCore,
                        deliverStatuses expectedStatuses: [CameraCoreStatus],
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        let spy = CameraStatusSpy(publisher: sut.getStatusPublisher())
        
        action()
        
        XCTAssertEqual(spy.loggedStatuses, expectedStatuses, file: file, line: line)
    }
}

extension AVCaptureDevice: MethodSwizzling {
    @objc convenience init(type: AVMediaType) {
        fatalError("should not come to here, swizzled by NSObject.init")
    }
    
    @objc static func makeVideoDevice(deviceType: AVCaptureDevice.DeviceType,
                                      mediaType: AVMediaType?,
                                      position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        mediaType.map { CaptureDeviceSpy(type: $0, position: position) }
    }
    
    @objc static func makeAudioDevice() -> AVCaptureDevice? {
        CaptureDeviceSpy(type: .audio, position: .unspecified)
    }
    
    var type: AVMediaType? {
        (self as? CaptureDeviceSpy)?.mediaType
    }
    
    static var instanceMethodPairs: [MethodPair] {
        [
            MethodPair(
                from: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.init(type:))),
                to: (class: AVCaptureDevice.self, method: #selector(NSObject.init))
            )
        ]
    }
    
    static var classMethodPairs: [MethodPair] {
        [
            MethodPair(
                from: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.default(_:for:position:))),
                to: (
                    class: AVCaptureDevice.self,
                    method: #selector(AVCaptureDevice.makeVideoDevice(deviceType:mediaType:position:))
                )
            ),
            MethodPair(
                from: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.default(for:))),
                to: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.makeAudioDevice))
            )
        ]
    }
}
