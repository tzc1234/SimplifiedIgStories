//
//  AVPhotoTakerTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 19/02/2024.
//

import XCTest
import AVKit
@testable import Simple_IG_Story

final class AVPhotoTakerTests: XCTestCase {
    func test_init_doesNotDeliverStatusUponInit() {
        let (sut, _) = makeSUT()
        let statusSpy = StatusSpy<PhotoTakerStatus>(publisher: sut.getStatusPublisher())
        
        XCTAssertTrue(statusSpy.loggedStatuses.isEmpty)
    }
    
    func test_takePhoto_addsPhotoOutputToSessionIfNoPhotoOutputWhenSessionIsRunning() {
        let (sut, device) = makeSUT(isSessionRunning: true)
        
        sut.takePhoto(on: .off)
        
        XCTAssertEqual(device.loggedPhotoOutputs.count, 1)
    }
    
    func test_takePhoto_doesNotAddPhotoOutputAgainWhenPhotoOutputIsAlreadyAddedAndSessionIsRunning() {
        let (sut, device) = makeSUT(isSessionRunning: true)
        
        sut.takePhoto(on: .off)
        sut.takePhoto(on: .off)
        
        XCTAssertEqual(device.loggedPhotoOutputs.count, 1)
    }
    
    func test_takePhoto_deliversAddPhotoOutputFailureStatusWhenCannotAddPhotoOutput() {
        let (sut, device) = makeSUT(isSessionRunning: true, canAddOutput: false)
        let statusSpy = StatusSpy<PhotoTakerStatus>(publisher: sut.getStatusPublisher())
        
        sut.takePhoto(on: .off)
        
        XCTAssertTrue(device.loggedPhotoOutputs.isEmpty)
        XCTAssertEqual(statusSpy.loggedStatuses, [.addPhotoOutputFailure])
    }
    
    func test_takePhoto_triggersCapturePhotoSuccessfullyWhenSessionIsRunning() throws {
        let photoOutputSpy = CapturePhotoOutputSpy()
        let flashMode: CameraFlashMode = .off
        let (sut, _) = makeSUT(isSessionRunning: true, capturePhotoOutput: { photoOutputSpy })
        
        sut.takePhoto(on: flashMode)
        
        assertCapturePhotoParams(in: photoOutputSpy, with: sut, andExpected: flashMode)
    }
    
    func test_takePhoto_doesNotTriggerCapturePhotoWhenSessionIsNotRunning() throws {
        let photoOutputSpy = CapturePhotoOutputSpy()
        let (sut, _) = makeSUT(isSessionRunning: false, capturePhotoOutput: { photoOutputSpy })
        
        sut.takePhoto(on: .off)
        
        XCTAssertEqual(photoOutputSpy.capturePhotoCallCount, 0)
    }
    
    func test_takePhoto_performsInSessionQueue() {
        let photoOutputSpy = CapturePhotoOutputSpy()
        var actions = [() -> Void]()
        let (sut, device) = makeSUT(
            isSessionRunning: true,
            capturePhotoOutput: { photoOutputSpy },
            perform: { actions.append($0) }
        )
        
        sut.takePhoto(on: .off)
        
        XCTAssertTrue(device.loggedPhotoOutputs.isEmpty)
        XCTAssertEqual(photoOutputSpy.capturePhotoCallCount, 0)
        
        let exp = expectation(description: "Wait for session queue")
        actions.forEach { action in
            action()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(device.loggedPhotoOutputs.count, 1)
        XCTAssertEqual(photoOutputSpy.capturePhotoCallCount, 1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(isSessionRunning: Bool = false,
                         canAddOutput: Bool = true,
                         capturePhotoOutput: @escaping () -> AVCapturePhotoOutput = CapturePhotoOutputSpy.init,
                         perform: @escaping (@escaping () -> Void) -> Void = { $0() },
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: AVPhotoTaker, device: PhotoCaptureDeviceSpy) {
        let device = PhotoCaptureDeviceSpy(
            isSessionRunning: isSessionRunning,
            canAddOutput: canAddOutput,
            performOnSessionQueue: perform
        )
        let sut = AVPhotoTaker(device: device, makeCapturePhotoOutput: capturePhotoOutput)
        trackForMemoryLeaks(device, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, device)
    }
    
    private func assertCapturePhotoParams(in output: CapturePhotoOutputSpy,
                                          with sut: AVPhotoTaker,
                                          andExpected flashMode: CameraFlashMode,
                                          file: StaticString = #filePath,
                                          line: UInt = #line) {
        XCTAssertEqual(output.capturePhotoCallCount, 1, file: file, line: line)
        XCTAssertIdentical(output.loggedDelegates.last, sut, file: file, line: line)
        let setting = output.loggedSettings.last
        XCTAssertEqual(setting?.flashMode, flashMode.toCaptureDeviceFlashMode(), file: file, line: line)
    }
    
    private final class PhotoCaptureDeviceSpy: PhotoCaptureDevice {
        let session: AVCaptureSession
        
        var loggedPhotoOutputs: [AVCapturePhotoOutput] {
            (session as! CaptureSessionSpy).loggedPhotoOutputs
        }
        
        private(set) var cameraPosition: CameraPosition = .back
        
        let performOnSessionQueue: (@escaping () -> Void) -> Void
        
        init(isSessionRunning: Bool,
             canAddOutput: Bool,
             performOnSessionQueue: @escaping (@escaping () -> Void) -> Void) {
            self.session = CaptureSessionSpy(isRunning: isSessionRunning, canAddOutput: canAddOutput)
            self.performOnSessionQueue = performOnSessionQueue
        }
    }
}

final class CapturePhotoOutputSpy: AVCapturePhotoOutput {
    struct CapturePhotoParam {
        let settings: AVCapturePhotoSettings
        weak var delegate: AVCapturePhotoCaptureDelegate?
    }
    
    private var loggedCapturePhotoParams = [CapturePhotoParam]()
    var capturePhotoCallCount: Int {
        loggedCapturePhotoParams.count
    }
    var loggedSettings: [AVCapturePhotoSettings] {
        loggedCapturePhotoParams.map(\.settings)
    }
    var loggedDelegates: [AVCapturePhotoCaptureDelegate] {
        loggedCapturePhotoParams.compactMap(\.delegate)
    }
    
    override func capturePhoto(with settings: AVCapturePhotoSettings, delegate: AVCapturePhotoCaptureDelegate) {
        loggedCapturePhotoParams.append(CapturePhotoParam(settings: settings, delegate: delegate))
    }
}

extension CameraFlashMode {
    func toCaptureDeviceFlashMode() -> AVCaptureDevice.FlashMode {
        switch self {
        case .on: return .on
        case .off: return .off
        case .auto: return .auto
        }
    }
}
