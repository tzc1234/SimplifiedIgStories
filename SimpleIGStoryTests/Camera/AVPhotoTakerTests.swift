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
        let (sut, device) = makeSUT()
        let statusSpy = StatusSpy<PhotoTakerStatus>(publisher: sut.getStatusPublisher())
        
        XCTAssertTrue(statusSpy.loggedStatuses.isEmpty)
    }
    
    func test_takePhoto_addsPhotoOutputToSessionIfNoPhotoOutputWhenSessionIsNotRunning() throws {
        let exp = expectation(description: "Wait for session queue")
        let (sut, device) = makeSUT(perform: { exp.fulfill() })
        
        sut.takePhoto(on: .off)
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(device.sessionSpy.loggedPhotoOutputs.count, 1)
    }
    
    func test_takePhoto_addsPhotoOutputToSessionIfNoPhotoOutputWhenSessionIsRunning() throws {
        let exp = expectation(description: "Wait for session queue")
        let (sut, device) = makeSUT(perform: { exp.fulfill() })
        
        sut.takePhoto(on: .off)
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(device.sessionSpy.loggedPhotoOutputs.count, 1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(isSessionRunning: Bool = false,
                         perform: @escaping () -> Void = {},
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: AVPhotoTaker, device: PhotoCaptureDeviceSpy) {
        let device = PhotoCaptureDeviceSpy(isSessionRunning: isSessionRunning, performOnSessionQueue: { action in
            action()
            perform()
        })
        let sut = AVPhotoTaker(device: device)
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
        private(set) var photoOutput: AVCapturePhotoOutput?
        
        let performOnSessionQueue: (@escaping () -> Void) -> Void
        
        init(isSessionRunning: Bool,
             performOnSessionQueue: @escaping (@escaping () -> Void) -> Void) {
            self.session = CaptureSessionSpy(isRunning: isSessionRunning)
            self.performOnSessionQueue = performOnSessionQueue
        }
    }
}
