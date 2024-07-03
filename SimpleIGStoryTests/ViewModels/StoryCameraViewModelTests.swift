//
//  StoryCameraViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 03/07/2024.
//

import XCTest
import Combine
@testable import Simple_IG_Story

final class StoryCameraViewModelTests: XCTestCase {
    @MainActor 
    func test_isCameraPermissionGranted_deliversNotGrantedWhenReceivedNotGrantedFromAuthorizationTracker() {
        let cameraAuthorizationTracker = AuthorizationTrackerSpy()
        let sut = makeSUT(cameraAuthorizationTracker: cameraAuthorizationTracker)
        
        cameraAuthorizationTracker.publish(permissionGranted: false)
        
        XCTAssertFalse(sut.isCameraPermissionGranted)
    }
    
    @MainActor
    func test_isCameraPermissionGranted_deliversGrantedWhenReceivedGrantedFromAuthorizationTracker() {
        let cameraAuthorizationTracker = AuthorizationTrackerSpy()
        let sut = makeSUT(cameraAuthorizationTracker: cameraAuthorizationTracker)
        
        cameraAuthorizationTracker.publish(permissionGranted: true)
        
        XCTAssertTrue(sut.isCameraPermissionGranted)
    }
    
    @MainActor
    func test_isMicrophonePermissionGranted_deliversNotGrantedWhenReceivedNotGrantedFromAuthorizationTracker() {
        let microphoneAuthorizationTracker = AuthorizationTrackerSpy()
        let sut = makeSUT(microphoneAuthorizationTracker: microphoneAuthorizationTracker)
        
        microphoneAuthorizationTracker.publish(permissionGranted: false)
        
        XCTAssertFalse(sut.isMicrophonePermissionGranted)
    }
    
    @MainActor
    func test_isMicrophonePermissionGranted_deliversGrantedWhenReceivedGrantedFromAuthorizationTracker() {
        let microphoneAuthorizationTracker = AuthorizationTrackerSpy()
        let sut = makeSUT(microphoneAuthorizationTracker: microphoneAuthorizationTracker)
        
        microphoneAuthorizationTracker.publish(permissionGranted: true)
        
        XCTAssertTrue(sut.isMicrophonePermissionGranted)
    }
    
    @MainActor
    func test_arePermissionsGranted_deliversNotGrantedWhenReceivedNotGrantedFromAuthorizationTrackers() {
        let cameraAuthorizationTracker = AuthorizationTrackerSpy()
        let microphoneAuthorizationTracker = AuthorizationTrackerSpy()
        let sut = makeSUT(
            cameraAuthorizationTracker: cameraAuthorizationTracker,
            microphoneAuthorizationTracker: microphoneAuthorizationTracker
        )
        
        cameraAuthorizationTracker.publish(permissionGranted: false)
        microphoneAuthorizationTracker.publish(permissionGranted: true)
        
        XCTAssertFalse(sut.arePermissionsGranted)
        
        cameraAuthorizationTracker.publish(permissionGranted: true)
        microphoneAuthorizationTracker.publish(permissionGranted: false)
        
        XCTAssertFalse(sut.arePermissionsGranted)
        
        cameraAuthorizationTracker.publish(permissionGranted: false)
        microphoneAuthorizationTracker.publish(permissionGranted: false)
        
        XCTAssertFalse(sut.arePermissionsGranted)
    }
    
    @MainActor
    func test_arePermissionsGranted_deliversGrantedWhenReceivedGrantedFromAuthorizationTrackers() {
        let cameraAuthorizationTracker = AuthorizationTrackerSpy()
        let microphoneAuthorizationTracker = AuthorizationTrackerSpy()
        let sut = makeSUT(
            cameraAuthorizationTracker: cameraAuthorizationTracker,
            microphoneAuthorizationTracker: microphoneAuthorizationTracker
        )
        
        cameraAuthorizationTracker.publish(permissionGranted: true)
        microphoneAuthorizationTracker.publish(permissionGranted: true)
        
        XCTAssertTrue(sut.arePermissionsGranted)
    }
    
    @MainActor
    func test_checkPermissions_startsTrackingOnAuthorizationTrackers() {
        let cameraAuthorizationTracker = AuthorizationTrackerSpy()
        let microphoneAuthorizationTracker = AuthorizationTrackerSpy()
        let sut = makeSUT(
            cameraAuthorizationTracker: cameraAuthorizationTracker,
            microphoneAuthorizationTracker: microphoneAuthorizationTracker
        )
        
        XCTAssertEqual(cameraAuthorizationTracker.startTrackingCallCount, 0)
        XCTAssertEqual(microphoneAuthorizationTracker.startTrackingCallCount, 0)
        
        sut.checkPermissions()
        
        XCTAssertEqual(cameraAuthorizationTracker.startTrackingCallCount, 1)
        XCTAssertEqual(microphoneAuthorizationTracker.startTrackingCallCount, 1)
    }
    
    @MainActor
    func test_videoPreviewLayer_deliversVideoPreviewLayerFromCamera() {
        let expectedVideoPreviewLayer = CALayer()
        let camera = CameraSpy(videoPreviewLayerStub: expectedVideoPreviewLayer)
        let sut = makeSUT(camera: camera)
        
        let receivedPreviewLayer = sut.videoPreviewLayer
        
        XCTAssertIdentical(receivedPreviewLayer, expectedVideoPreviewLayer)
    }
    
    @MainActor
    func test_startSession_startsSessionOnCamera() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        
        XCTAssertEqual(camera.startSessionCallCount, 0)
        
        sut.startSession()
        
        XCTAssertEqual(camera.startSessionCallCount, 1)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeSUT(camera: CameraSpy = CameraSpy(),
                         cameraAuthorizationTracker: AuthorizationTrackerSpy = AuthorizationTrackerSpy(),
                         microphoneAuthorizationTracker : AuthorizationTrackerSpy = AuthorizationTrackerSpy(),
                         file: StaticString = #filePath,
                         line: UInt = #line) -> StoryCameraViewModel {
        let sut = StoryCameraViewModel(
            camera: camera,
            cameraAuthorizationTracker: cameraAuthorizationTracker,
            microphoneAuthorizationTracker: microphoneAuthorizationTracker,
            scheduler: DispatchQueue.immediateWhenOnMainQueueScheduler
        )
        trackForMemoryLeaks(camera, file: file, line: line)
        trackForMemoryLeaks(cameraAuthorizationTracker, file: file, line: line)
        trackForMemoryLeaks(microphoneAuthorizationTracker, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private class AuthorizationTrackerSpy: DeviceAuthorizationTracker {
        private let authorizationPublisher = PassthroughSubject<Bool, Never>()
        private(set) var startTrackingCallCount = 0
        
        func getPublisher() -> AnyPublisher<Bool, Never> {
            authorizationPublisher.eraseToAnyPublisher()
        }
        
        func startTracking() {
            startTrackingCallCount += 1
        }
        
        func publish(permissionGranted: Bool) {
            authorizationPublisher.send(permissionGranted)
        }
    }
    
    private class CameraSpy: Camera {
        var cameraPosition = CameraPosition.back
        private(set) var startSessionCallCount = 0
        
        private let videoPreviewLayerStub: CALayer
        
        init(videoPreviewLayerStub: CALayer = CALayer()) {
            self.videoPreviewLayerStub = videoPreviewLayerStub
        }
        
        var videoPreviewLayer: CALayer {
            videoPreviewLayerStub
        }
        
        func getStatusPublisher() -> AnyPublisher<CameraStatus, Never> {
            Empty().eraseToAnyPublisher()
        }
        
        func startSession() {
            startSessionCallCount += 1
        }
        
        func stopSession() {
            
        }
        
        func switchCamera() {
            
        }
        
        func takePhoto(on flashMode: CameraFlashMode) {
            
        }
        
        func startRecording() {
            
        }
        
        func stopRecording() {
            
        }
        
        func focus(on point: CGPoint) {
            
        }
        
        func zoom(to factor: CGFloat) {
            
        }
    }
}
