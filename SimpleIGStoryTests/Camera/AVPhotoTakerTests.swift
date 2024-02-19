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
        let device = PhotoCaptureDeviceSpy(performOnSessionQueue: { _ in })
        let sut = AVPhotoTaker(device: device)
        let statusSpy = StatusSpy<PhotoTakerStatus>(publisher: sut.getStatusPublisher())
        
        XCTAssertTrue(statusSpy.loggedStatuses.isEmpty)
    }
    
    // MARK: - Helpers
    
    private final class PhotoCaptureDeviceSpy: PhotoCaptureDevice {
        private(set) var cameraPosition: CameraPosition = .back
        private(set) var photoOutput: AVCapturePhotoOutput?
        
        let performOnSessionQueue: (@escaping () -> Void) -> Void
        
        init(performOnSessionQueue: @escaping (@escaping () -> Void) -> Void) {
            self.performOnSessionQueue = performOnSessionQueue
        }
    }
}
