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
        AVCaptureDevice.revertSwizzled()
    }
    
    func test_startSession_doesNotAddInputsWhenSessionIsRunning() throws {
        AVCaptureDevice.swizzled()
        let sessionSpy = CaptureSessionSpy(isRunning: true)
        let captureInput = makeCaptureInput()
        let exp = expectation(description: "Wait for session queue")
        let sut = AVCamera(
            session: sessionSpy,
            makeCaptureDeviceInput: { _ in
                captureInput
            },
            performOnSessionQueue: { action in
                action()
                exp.fulfill()
            }
        )
        
        sut.startSession()
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(sessionSpy.loggedInputs, [])
        AVCaptureDevice.revertSwizzled()
    }
    
    func test_startSession_setsFocusModeAndExposureModeProperlyWhenSessionIsNotRunning() throws {
        AVCaptureDevice.swizzled()
        let sessionSpy = CaptureSessionSpy(isRunning: false)
        let exp = expectation(description: "Wait for session queue")
        var loggedDevices = Set<AVCaptureDevice>()
        let sut = AVCamera(
            session: sessionSpy,
            makeCaptureDeviceInput: { device in
                loggedDevices.insert(device)
                return self.makeCaptureInput()
            },
            performOnSessionQueue: { action in
                action()
                exp.fulfill()
            }
        )
        
        sut.startSession()
        wait(for: [exp], timeout: 1)
        
        let videoDevice = loggedDevices.first(where: { $0.type == .video })
        XCTAssertEqual(videoDevice?.focusMode, .continuousAutoFocus)
        XCTAssertEqual(videoDevice?.exposureMode, .continuousAutoExposure)
        AVCaptureDevice.revertSwizzled()
    }
    
    func test_startSession_deliversSessionStartedStatus() {
        AVCaptureDevice.swizzled()
        let sessionSpy = CaptureSessionSpy(isRunning: false)
        let exp = expectation(description: "Wait for session queue")
        let sut = AVCamera(
            session: sessionSpy,
            makeCaptureDeviceInput: { _ in
                self.makeCaptureInput()
            },
            performOnSessionQueue: { action in
                action()
                exp.fulfill()
            }
        )
        let spy = CameraStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.startSession()
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(spy.loggedStatuses, [.sessionStarted])
        AVCaptureDevice.revertSwizzled()
    }
    
    // MARK: - Helpers
    
    private func makeCaptureInput() -> AVCaptureInput {
        let klass = AVCaptureInput.self as NSObject.Type
        return klass.init() as! AVCaptureInput
    }
    
    private class CameraStatusSpy {
        private(set) var loggedStatuses = [CameraStatus]()
        private var cancellables = Set<AnyCancellable>()
        
        init(publisher: AnyPublisher<CameraStatus, Never>) {
            publisher
                .sink { [weak self] status in
                    self?.loggedStatuses.append(status)
                }
                .store(in: &cancellables)
        }
    }
}

extension AVCaptureDevice {
    struct MethodPair {
        let from: (class: AnyClass, method: Selector)
        let to: (class: AnyClass, method: Selector)
    }
    
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
                to: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.makeVideoDevice))
            ),
            MethodPair(
                from: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.default(for:))),
                to: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.makeAudioDevice))
            )
        ]
    }
    
    static func swizzled() {
        instanceMethodPairs.forEach { pair in
            method_exchangeImplementations(
                class_getInstanceMethod(pair.from.class, pair.from.method)!,
                class_getInstanceMethod(pair.to.class, pair.to.method)!
            )
        }
        
        classMethodPairs.forEach { pair in
            method_exchangeImplementations(
                class_getClassMethod(pair.from.class, pair.from.method)!,
                class_getClassMethod(pair.to.class, pair.to.method)!
            )
        }
    }
    
    static func revertSwizzled() {
        instanceMethodPairs.forEach { pair in
            method_exchangeImplementations(
                class_getInstanceMethod(pair.to.class, pair.to.method)!,
                class_getInstanceMethod(pair.from.class, pair.from.method)!
            )
        }
        
        classMethodPairs.forEach { pair in
            method_exchangeImplementations(
                class_getClassMethod(pair.to.class, pair.to.method)!,
                class_getClassMethod(pair.from.class, pair.from.method)!
            )
        }
    }
}

final class CaptureDeviceSpy: AVCaptureDevice {
    private var _focusMode = FocusMode.locked
    private var _exposureMode = ExposureMode.locked
    let mediaType: AVMediaType
    
    init(type: AVMediaType) {
        self.mediaType = type
        super.init(type: type)
    }
    
    override var focusMode: FocusMode {
        get { _focusMode }
        set { _focusMode = newValue }
    }
    
    override var exposureMode: ExposureMode {
        get { _exposureMode }
        set { _exposureMode = newValue }
    }
    
    override func isFocusModeSupported(_ focusMode: FocusMode) -> Bool {
        true
    }
    
    override func isExposureModeSupported(_ exposureMode: ExposureMode) -> Bool {
        true
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
        NotificationCenter.default.post(name: .AVCaptureSessionDidStartRunning, object: nil)
    }
}
