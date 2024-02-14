//
//  AVCaptureCameraTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 14/02/2024.
//

import XCTest
import Combine
import AVFoundation
@testable import Simple_IG_Story

final class AVCaptureCameraTests: XCTestCase {
    func test_init_doesNotDeliverAnyStatusUponInit() {
        let sut = AVCamera()
        let spy = CameraStatusSpy(publisher: sut.getStatusPublisher())
        
        XCTAssertEqual(spy.loggedStatuses, [])
    }
    
    func test_videoPreviewLayer_returnPreviewLayerProperly() {
        let sut = AVCamera()
        
        let previewLayer = sut.videoPreviewLayer
        
        XCTAssertNotNil(previewLayer as? AVCaptureVideoPreviewLayer)
    }
    
    func test_startSession_ensuresInputsAreAddedToSessionProperlyWhenSessionIsNotRunning() throws {
        AVCaptureDevice.swizzled()
        let sessionSpy = CaptureSessionSpy(isRunning: false)
        let captureInput = makeCaptureInput()
        let exp = expectation(description: "Wait for session queue")
        var loggedDeviceTypes = Set<AVMediaType?>()
        let sut = AVCamera(
            session: sessionSpy,
            makeCaptureDeviceInput: { device in
                loggedDeviceTypes.insert(device.type)
                return captureInput
            },
            performOnSessionQueue: { action in
                action()
                exp.fulfill()
            }
        )
        
        sut.startSession()
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(sessionSpy.loggedInputs, [captureInput, captureInput])
        XCTAssertEqual(loggedDeviceTypes, [.video, .audio])
        XCTAssertEqual(sessionSpy.startRunningCallCount, 1)
    }
    
    // MARK: - Helpers
    
    private func makeCaptureInput() -> AVCaptureInput {
        let klass = AVCaptureInput.self as NSObject.Type
        return klass.init() as! AVCaptureInput
    }
    
    private class CameraStatusSpy {
        private(set) var loggedStatuses = [CameraStatus]()
        
        init(publisher: AnyPublisher<CameraStatus, Never>) {
            
        }
    }
}

extension AVCaptureDevice {
    @objc convenience init(type: AVMediaType) {
        fatalError("should not come to here, swizzled by NSObject.init")
    }
    
    @objc static func makeVideoDevice() -> AVCaptureDevice? {
        CaptureDeviceSpy(type: .video)
    }
    
    @objc static func makeAudioDevice() -> AVCaptureDevice? {
        CaptureDeviceSpy(type: .audio)
    }
    
    var type: AVMediaType? {
        (self as? CaptureDeviceSpy)?.mediaType
    }
    
    static func swizzled() {
        method_exchangeImplementations(
            class_getInstanceMethod(AVCaptureDevice.self, #selector(AVCaptureDevice.init(type:)))!,
            class_getInstanceMethod(AVCaptureDevice.self, #selector(NSObject.init))!
        )
        
        method_exchangeImplementations(
            class_getClassMethod(AVCaptureDevice.self, #selector(AVCaptureDevice.default(_:for:position:)))!,
            class_getClassMethod(AVCaptureDevice.self, #selector(AVCaptureDevice.makeVideoDevice))!
        )
        
        method_exchangeImplementations(
            class_getClassMethod(AVCaptureDevice.self, #selector(AVCaptureDevice.default(for:)))!,
            class_getClassMethod(AVCaptureDevice.self, #selector(AVCaptureDevice.makeAudioDevice))!
        )
    }
}

final class CaptureDeviceSpy: AVCaptureDevice {
    let mediaType: AVMediaType
    
    init(type: AVMediaType) {
        self.mediaType = type
        super.init(type: type)
    }
}

final class CaptureSessionSpy: AVCaptureSession {
    private(set) var loggedInputs = [AVCaptureInput]()
    private(set) var startRunningCallCount = 0
    
    private var _isRunning = false
    
    init(isRunning: Bool) {
        self._isRunning = isRunning
    }
    
    override var isRunning: Bool {
        _isRunning
    }
    
    override func canAddInput(_ input: AVCaptureInput) -> Bool {
        true
    }
    
    override func addInput(_ input: AVCaptureInput) {
        loggedInputs.append(input)
    }
    
    override func startRunning() {
        startRunningCallCount += 1
    }
}
