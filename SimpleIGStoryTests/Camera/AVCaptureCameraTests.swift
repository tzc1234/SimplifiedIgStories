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
        let (sut, _) = makeSUT()
        let spy = CameraStatusSpy(publisher: sut.getStatusPublisher())
        
        XCTAssertEqual(spy.loggedStatuses, [])
    }
    
    func test_videoPreviewLayer_returnPreviewLayerProperly() {
        let (sut, _) = makeSUT()
        
        let previewLayer = sut.videoPreviewLayer
        
        XCTAssertNotNil(previewLayer as? AVCaptureVideoPreviewLayer)
    }
    
    func test_startSession_ensuresInputsAreAddedToSessionProperlyWhenSessionIsNotRunning() {
        let captureInput = makeCaptureInput()
        let exp = expectation(description: "Wait for session queue")
        var loggedDeviceTypes = Set<AVMediaType?>()
        let (sut, session) = makeSUT(
            isSessionRunning: false,
            captureDeviceInput: { device in
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
        
        XCTAssertEqual(session.loggedInputs, [captureInput, captureInput])
        XCTAssertEqual(loggedDeviceTypes, [.video, .audio])
    }
    
    func test_startSession_doesNotAddInputsWhenSessionIsRunning() {
        let exp = expectation(description: "Wait for session queue")
        let (sut, session) = makeSUT(
            isSessionRunning: true,
            performOnSessionQueue: { action in
                action()
                exp.fulfill()
            }
        )
        
        sut.startSession()
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(session.loggedInputs, [])
    }
    
    func test_startSession_setsFocusModeAndExposureModeProperlyWhenSessionIsNotRunning() {
        let exp = expectation(description: "Wait for session queue")
        var loggedDevices = Set<AVCaptureDevice>()
        let (sut, _) = makeSUT(
            isSessionRunning: false,
            captureDeviceInput: { device in
                loggedDevices.insert(device)
                return makeCaptureInput()
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
    }
    
    func test_startSession_deliversSessionStartedStatusAfterStartSession() {
        let exp = expectation(description: "Wait for session queue")
        let (sut, _) = makeSUT(
            isSessionRunning: false,
            performOnSessionQueue: { action in
                action()
                exp.fulfill()
            }
        )
        
        expect(sut, deliverStatuses: [.sessionStarted], when: {
            sut.startSession()
        })
        wait(for: [exp], timeout: 1)
    }
    
    func test_stopSession_deliversSessionStoppedStatusAfterStopSession() {
        let exp = expectation(description: "Wait for session queue")
        let (sut, _) = makeSUT(
            isSessionRunning: false,
            performOnSessionQueue: { action in
                action()
                exp.fulfill()
            }
        )
        
        expect(sut, deliverStatuses: [.sessionStarted, .sessionStopped], when: {
            sut.startSession()
            sut.stopSession()
        })
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(isSessionRunning: Bool = false,
                         captureDeviceInput: @escaping (AVCaptureDevice) throws -> AVCaptureInput
                            = { _ in makeCaptureInput() },
                         performOnSessionQueue: @escaping (@escaping () -> Void) -> Void = { $0() })
    -> (sut: AVCamera, session: CaptureSessionSpy) {
        AVCaptureDevice.swizzled()
        let session = CaptureSessionSpy(isRunning: isSessionRunning)
        let sut = AVCamera(
            session: session,
            makeCaptureDeviceInput: captureDeviceInput,
            performOnSessionQueue: performOnSessionQueue
        )
        addTeardownBlock {
            AVCaptureDevice.revertSwizzled()
        }
        return (sut, session)
    }
    
    private func expect(_ sut: AVCamera,
                        deliverStatuses expectedStatuses: [CameraStatus],
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        let spy = CameraStatusSpy(publisher: sut.getStatusPublisher())
        
        action()
        
        XCTAssertEqual(spy.loggedStatuses, expectedStatuses, file: file, line: line)
    }
    
    private class CameraStatusSpy {
        private(set) var loggedStatuses = [CameraStatus]()
        private var cancellable: AnyCancellable?
        
        init(publisher: AnyPublisher<CameraStatus, Never>) {
            cancellable = publisher
                .sink { [weak self] status in
                    self?.loggedStatuses.append(status)
                }
        }
    }
}

func makeCaptureInput() -> AVCaptureInput {
    let klass = AVCaptureInput.self as NSObject.Type
    return klass.init() as! AVCaptureInput
}

extension AVCaptureDevice {
    struct MethodPair {
        typealias Pair = (class: AnyClass, method: Selector)
        
        let from: Pair
        let to: Pair
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
        NotificationCenter.default.post(name: .AVCaptureSessionDidStartRunning, object: nil)
    }
    
    override func stopRunning() {
        NotificationCenter.default.post(name: .AVCaptureSessionDidStopRunning, object: nil)
    }
}
