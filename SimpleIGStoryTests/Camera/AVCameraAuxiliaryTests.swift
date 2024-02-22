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
        let (sut, _) = makeSUT()
        let statusSpy = CameraAuxiliaryStatusSpy(publisher: sut.getStatusPublisher())
        
        XCTAssertTrue(statusSpy.loggedStatuses.isEmpty)
    }
    
    func test_focus_deliversCaptureDeviceNotFoundStatusWhenNoCaptureDeviceFound() {
        let (sut, _) = makeSUT(captureDevice: nil)
        let statusSpy = CameraAuxiliaryStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.focus(on: .zero)
        
        XCTAssertEqual(statusSpy.loggedStatuses, [.captureDeviceNotFound])
    }
    
    // MARK: - Helpers
    
    private typealias CameraAuxiliaryStatusSpy = StatusSpy<CameraAuxiliaryStatus>
    
    private func makeSUT(captureDevice: AVCaptureDevice? = nil,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: AVCameraAuxiliary, camera: AuxiliarySupportedCameraSpy) {
        let camera = AuxiliarySupportedCameraSpy(captureDevice: captureDevice, performOnSessionQueue: { $0() })
        let sut = AVCameraAuxiliary(camera: camera)
        trackForMemoryLeaks(camera, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, camera)
    }
    
    private final class AuxiliarySupportedCameraSpy: AuxiliarySupportedCamera {
        let captureDevice: AVCaptureDevice?
        let performOnSessionQueue: (@escaping () -> Void) -> Void
        
        init(captureDevice: AVCaptureDevice?, performOnSessionQueue: @escaping (@escaping () -> Void) -> Void) {
            self.captureDevice = captureDevice
            self.performOnSessionQueue = performOnSessionQueue
        }
    }
}
