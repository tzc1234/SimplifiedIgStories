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
        let sut = AVCamera()
        let spy = CameraStatusSpy(publisher: sut.getStatusPublisher())
        
        XCTAssertEqual(spy.loggedStatuses, [])
    }
    
    func test_videoPreviewLayer_returnPreviewLayerProperly() {
        let sut = AVCamera()
        
        let previewLayer = sut.videoPreviewLayer
        
        XCTAssertNotNil(previewLayer as? AVCaptureVideoPreviewLayer)
    }
    
    // MARK: - Helpers
    
    private class CameraStatusSpy {
        private(set) var loggedStatuses = [CameraStatus]()
        
        init(publisher: AnyPublisher<CameraStatus, Never>) {
            
        }
    }
}
