//
//  AVCameraAuxiliaryTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 22/02/2024.
//

import XCTest
import AVFoundation
@testable import Simple_IG_Story

final class AVCameraAuxiliaryTests: XCTestCase {
    func test_init_doesNotDeliverStatusUponInit() {
        let camera = AuxiliarySupportedCameraSpy(performOnSessionQueue: { _ in })
        let sut = AVCameraAuxiliary(camera: camera)
        let statusSpy = CameraAuxiliaryStatusSpy(publisher: sut.getStatusPublisher())
        
        XCTAssertTrue(statusSpy.loggedStatuses.isEmpty)
    }
    
    // MARK: - Helpers
    
    private typealias CameraAuxiliaryStatusSpy = StatusSpy<CameraAuxiliaryStatus>
    
    private final class AuxiliarySupportedCameraSpy: AuxiliarySupportedCamera {
        var captureDevice: AVCaptureDevice?
        var performOnSessionQueue: (@escaping () -> Void) -> Void
        
        init(performOnSessionQueue: @escaping (@escaping () -> Void) -> Void) {
            self.performOnSessionQueue = performOnSessionQueue
        }
    }
}
