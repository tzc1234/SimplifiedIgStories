//
//  AVCameraTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 14/02/2024.
//

import XCTest
import AVFoundation
@testable import Simple_IG_Story

final class AVCameraTests: XCTestCase {
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
        let exp = expectation(description: "Wait for session queue")
        var loggedDeviceTypes = Set<AVMediaType?>()
        let (sut, session) = makeSUT(
            isSessionRunning: false,
            captureDeviceInput: { device in
                loggedDeviceTypes.insert(device.type)
                return makeDummyCaptureInput()
            },
            afterPerformOnSessionQueue: {
                exp.fulfill()
            }
        )
        
        sut.startSession()
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(session.loggedInputs.count, 2)
        XCTAssertEqual(loggedDeviceTypes, [.video, .audio])
    }
    
    func test_startSession_doesNotAddInputsWhenSessionIsRunning() {
        let exp = expectation(description: "Wait for session queue")
        let (sut, session) = makeSUT(
            isSessionRunning: true,
            afterPerformOnSessionQueue: {
                exp.fulfill()
            }
        )
        
        sut.startSession()
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(session.loggedInputs, [])
    }
    
    func test_startSession_ensuresVideoDeviceSettingsWhenSessionIsNotRunning() {
        let exp = expectation(description: "Wait for session queue")
        var loggedDevices = [AVCaptureDevice]()
        let (sut, _) = makeSUT(
            isSessionRunning: false,
            captureDeviceInput: { device in
                loggedDevices.append(device)
                return makeDummyCaptureInput()
            },
            afterPerformOnSessionQueue: {
                exp.fulfill()
            }
        )
        
        sut.startSession()
        wait(for: [exp], timeout: 1)
        
        assertVideoDeviceSettings(in: loggedDevices, withExpectedPosition: sut.cameraPosition)
    }
    
    func test_startSession_deliversSessionStartedStatusAfterStartSession() {
        let exp = expectation(description: "Wait for session queue")
        let (sut, _) = makeSUT(
            isSessionRunning: false,
            afterPerformOnSessionQueue: {
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
            afterPerformOnSessionQueue: {
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
                return makeDummyCaptureInput()
            },
            afterPerformOnSessionQueue: {
                exp.fulfill()
            }
        )
        let initialPosition = sut.cameraPosition
        
        sut.startSession()
        sut.switchCamera()
        wait(for: [exp], timeout: 1)
        
        assertVideoDeviceSettings(in: loggedDevices, withExpectedPosition: initialPosition.toggle())
    }
    
    func test_switchCamera_reAddsInputsToSession() {
        let exp = expectation(description: "Wait for session queue")
        exp.expectedFulfillmentCount = 2
        var loggedDeviceTypes = Set<AVMediaType?>()
        let (sut, session) = makeSUT(
            isSessionRunning: false,
            captureDeviceInput: { device in
                loggedDeviceTypes.insert(device.type)
                return makeDummyCaptureInput()
            },
            afterPerformOnSessionQueue: {
                exp.fulfill()
            }
        )
        
        sut.startSession()
        session.resetLoggedInputs()
        loggedDeviceTypes.removeAll()
        
        sut.switchCamera()
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(session.loggedInputs.count, 2)
        XCTAssertEqual(session.loggedConfigurationStatus, [.begin, .commit])
        XCTAssertEqual(loggedDeviceTypes, [.video, .audio])
    }
    
    func test_switchCamera_deliversCameraSwitchedStatus() {
        let exp = expectation(description: "Wait for session queue")
        let (sut, _) = makeSUT(
            isSessionRunning: false,
            afterPerformOnSessionQueue: {
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
    
    typealias CameraStatusSpy = StatusSpy<CameraStatus>
    
    private func makeSUT(isSessionRunning: Bool = false,
                         captureDeviceInput: @escaping (AVCaptureDevice) throws -> AVCaptureInput
                            = { _ in makeDummyCaptureInput() },
                         afterPerformOnSessionQueue: @escaping () -> Void = {})
    -> (sut: AVCamera, session: CaptureSessionSpy) {
        AVCaptureDevice.swizzled()
        let session = CaptureSessionSpy(isRunning: isSessionRunning, canAddOutput: false)
        let sut = AVCamera(
            session: session,
            makeCaptureDeviceInput: captureDeviceInput,
            performOnSessionQueue: { action in
                action()
                afterPerformOnSessionQueue()
            }
        )
        addTeardownBlock {
            AVCaptureDevice.revertSwizzled()
        }
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
    
    private func expect(_ sut: AVCamera,
                        deliverStatuses expectedStatuses: [CameraStatus],
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        let spy = CameraStatusSpy(publisher: sut.getStatusPublisher())
        
        action()
        
        XCTAssertEqual(spy.loggedStatuses, expectedStatuses, file: file, line: line)
    }
}

func makeDummyCaptureInput() -> AVCaptureInput {
    let klass = AVCaptureInput.self as NSObject.Type
    return klass.init() as! AVCaptureInput
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
            .init(
                from: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.init(type:))),
                to: (class: AVCaptureDevice.self, method: #selector(NSObject.init))
            )
        ]
    }
    
    static var classMethodPairs: [MethodPair] {
        [
            .init(
                from: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.default(_:for:position:))),
                to: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.makeVideoDevice(deviceType:mediaType:position:)))
            ),
            .init(
                from: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.default(for:))),
                to: (class: AVCaptureDevice.self, method: #selector(AVCaptureDevice.makeAudioDevice))
            )
        ]
    }
}
