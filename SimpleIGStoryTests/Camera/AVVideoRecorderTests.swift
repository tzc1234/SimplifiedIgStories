//
//  AVVideoRecorderTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 20/02/2024.
//

import XCTest
import AVFoundation
@testable import Simple_IG_Story

final class AVVideoRecorderTests: XCTestCase {
    func test_init_doesNotDeliverStatusUponInit() {
        let device = VideoRecordDeviceSpy(performOnSessionQueue: { _ in })
        let sut = AVVideoRecorder(device: device)
        let statusSpy = VideoRecorderStatusSpy(publisher: sut.getStatusPublisher())
        
        XCTAssertTrue(statusSpy.loggedStatuses.isEmpty)
    }
    
    // MARK: - Helpers
    
    private typealias VideoRecorderStatusSpy = StatusSpy<VideoRecorderStatus>
    
    private final class VideoRecordDeviceSpy: VideoRecordDevice {
        private(set) var cameraPosition = CameraPosition.back
        private(set) var movieFileOutput: AVCaptureMovieFileOutput?
        
        let performOnSessionQueue: (@escaping () -> Void) -> Void
        
        init(performOnSessionQueue: @escaping (@escaping () -> Void) -> Void) {
            self.performOnSessionQueue = performOnSessionQueue
        }
    }
}
