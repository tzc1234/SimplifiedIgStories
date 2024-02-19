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
        let photoOutputSpy = CapturePhotoOutputSpy()
        let exp = expectation(description: "Wait for session queue")
        let (sut, device) = makeSUT(
            isSessionRunning: true,
            capturePhotoOutput: { photoOutputSpy },
            perform: { exp.fulfill() }
        )
        
        sut.takePhoto(on: .off)
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(device.sessionSpy.loggedPhotoOutputs.count, 1)
    }
    
    func test_takePhoto_triggersCapturePhotoSuccessfully() throws {
        let photoOutputSpy = CapturePhotoOutputSpy()
        let flashMode: CameraFlashMode = .off
        let exp = expectation(description: "Wait for session queue")
        let (sut, _) = makeSUT(
            isSessionRunning: true,
            capturePhotoOutput: { photoOutputSpy },
            perform: { exp.fulfill() }
        )
        
        sut.takePhoto(on: flashMode)
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(photoOutputSpy.loggedCapturePhotos.count, 1)
        XCTAssertIdentical(photoOutputSpy.loggedDelegates.last, sut)
        let setting = photoOutputSpy.loggedSettings.last
        XCTAssertEqual(setting?.flashMode, flashMode.toCaptureDeviceFlashMode())
    }
    
    // MARK: - Helpers
    
    private func makeSUT(isSessionRunning: Bool = false,
                         capturePhotoOutput: @escaping () -> AVCapturePhotoOutput = AVCapturePhotoOutput.init,
                         perform: @escaping () -> Void = {},
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: AVPhotoTaker, device: PhotoCaptureDeviceSpy) {
        let device = PhotoCaptureDeviceSpy(
            isSessionRunning: isSessionRunning,
            performOnSessionQueue: { action in
                action()
                perform()
            })
        let sut = AVPhotoTaker(device: device, makeCapturePhotoOutput: capturePhotoOutput)
        trackForMemoryLeaks(device, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, device)
    }
    
    private final class PhotoCaptureDeviceSpy: PhotoCaptureDevice {
        let session: AVCaptureSession
        var sessionSpy: CaptureSessionSpy {
            session as! CaptureSessionSpy
        }
        
        private(set) var cameraPosition: CameraPosition = .back
        
        let performOnSessionQueue: (@escaping () -> Void) -> Void
        
        init(isSessionRunning: Bool,
             performOnSessionQueue: @escaping (@escaping () -> Void) -> Void) {
            self.session = CaptureSessionSpy(isRunning: isSessionRunning)
            self.performOnSessionQueue = performOnSessionQueue
        }
    }
}

final class CapturePhotoOutputSpy: AVCapturePhotoOutput {
    struct CapturePhoto {
        let settings: AVCapturePhotoSettings
        weak var delegate: AVCapturePhotoCaptureDelegate?
    }
    
    private(set) var loggedCapturePhotos = [CapturePhoto]()
    var loggedSettings: [AVCapturePhotoSettings] {
        loggedCapturePhotos.map(\.settings)
    }
    var loggedDelegates: [AVCapturePhotoCaptureDelegate] {
        loggedCapturePhotos.compactMap(\.delegate)
    }
    
    func resetLoggedCapturePhotos() {
        loggedCapturePhotos.removeAll()
    }
    
    override func capturePhoto(with settings: AVCapturePhotoSettings, delegate: AVCapturePhotoCaptureDelegate) {
        loggedCapturePhotos.append(CapturePhoto(settings: settings, delegate: delegate))
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
