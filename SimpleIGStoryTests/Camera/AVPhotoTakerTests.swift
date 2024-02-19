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
        let device = PhotoCaptureDeviceSpy(isSessionRunning: false, performOnSessionQueue: { _ in })
        let sut = AVPhotoTaker(device: device)
        let statusSpy = StatusSpy<PhotoTakerStatus>(publisher: sut.getStatusPublisher())
        
        XCTAssertTrue(statusSpy.loggedStatuses.isEmpty)
    }
    
    func test_takePhoto_addsPhotoOutputToSessionIfNoPhotoOutputWhenSessionIsNotRunning() throws {
        let exp = expectation(description: "Wait for session queue")
        let device = PhotoCaptureDeviceSpy(isSessionRunning: false, performOnSessionQueue: { action in
            action()
            exp.fulfill()
        })
        let sut = AVPhotoTaker(device: device)
        
        sut.takePhoto(on: .off)
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(device.sessionSpy?.loggedOutputs.count, 1)
    }
    
    // MARK: - Helpers
    
    private final class PhotoCaptureDeviceSpy: PhotoCaptureDevice {
        let session: AVCaptureSession
        var sessionSpy: CaptureSessionSpy? {
            session as? CaptureSessionSpy
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
