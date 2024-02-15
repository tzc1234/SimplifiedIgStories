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
        var loggedDevices = [AVCaptureDevice]()
        let (sut, _) = makeSUT(
            isSessionRunning: false,
            captureDeviceInput: { device in
                loggedDevices.append(device)
                return makeCaptureInput()
            },
            performOnSessionQueue: { action in
                action()
                exp.fulfill()
            }
        )
        
        sut.startSession()
        wait(for: [exp], timeout: 1)
        
        let videoDevice = loggedDevices.last(where: { $0.type == .video })
        XCTAssertEqual(videoDevice?.focusMode, .continuousAutoFocus)
        XCTAssertEqual(videoDevice?.exposureMode, .continuousAutoExposure)
        XCTAssertEqual(videoDevice?.position, sut.cameraPosition.toCaptureDevicePosition())
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
    
    func test_switchCamera_switchesCameraPosition() {
        let exp = expectation(description: "Wait for session queue")
        exp.expectedFulfillmentCount = 2
        var loggedDevices = [AVCaptureDevice]()
        let (sut, _) = makeSUT(
            isSessionRunning: false,
            captureDeviceInput: { device in
                loggedDevices.append(device)
                return makeCaptureInput()
            },
            performOnSessionQueue: { action in
                action()
                exp.fulfill()
            }
        )
        
        let initialPosition = sut.cameraPosition
        
        sut.startSession()
        sut.switchCamera()
        wait(for: [exp], timeout: 1)
        
        let videoDevice = loggedDevices.last(where: { $0.type == .video })
        XCTAssertEqual(videoDevice?.focusMode, .continuousAutoFocus)
        XCTAssertEqual(videoDevice?.exposureMode, .continuousAutoExposure)
        XCTAssertEqual(videoDevice?.position, sut.cameraPosition.toCaptureDevicePosition())
        XCTAssertNotEqual(sut.cameraPosition, initialPosition)
    }
    
    func test_switchCamera_reAddsInputsToSession() {
        let captureInput = makeCaptureInput()
        let exp = expectation(description: "Wait for session queue")
        exp.expectedFulfillmentCount = 2
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
        session.resetLoggedInputs()
        loggedDeviceTypes.removeAll()
        
        sut.switchCamera()
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(session.loggedInputs, [captureInput, captureInput])
        XCTAssertEqual(loggedDeviceTypes, [.video, .audio])
    }
    
    func test_switchCamera_deliversCameraSwitchedStatus() {
        let exp = expectation(description: "Wait for session queue")
        let (sut, _) = makeSUT(
            isSessionRunning: false,
            performOnSessionQueue: { action in
                action()
                exp.fulfill()
            }
        )
        
        let initialPosition = sut.cameraPosition
        
        expect(sut, deliverStatuses: [.cameraSwitched(position: initialPosition.toggle())], when: {
            sut.switchCamera()
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
                to: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.makeVideoDevice(deviceType:mediaType:position:)))
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
    private var _position = AVCaptureDevice.Position.unspecified
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
    
    override var exposureMode: ExposureMode {
        get { _exposureMode }
        set { _exposureMode = newValue }
    }
    
    override var position: AVCaptureDevice.Position {
        get { _position }
        set { _position = newValue }
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
    
    func resetLoggedInputs() {
        loggedInputs.removeAll()
    }
}

extension CameraPosition {
    func toCaptureDevicePosition() -> AVCaptureDevice.Position {
        switch self {
        case .back: return .back
        case .front: return .front
        }
    }
    
    func toggle() -> CameraPosition {
        self == .back ? .front : .back
    }
}
