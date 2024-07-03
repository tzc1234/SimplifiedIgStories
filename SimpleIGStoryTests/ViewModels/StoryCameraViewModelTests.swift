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
    
    // MARK: - Helpers
    
    @MainActor
    private func makeSUT(cameraAuthorizationTracker: AuthorizationTrackerSpy = AuthorizationTrackerSpy(),
                         microphoneAuthorizationTracker : AuthorizationTrackerSpy = AuthorizationTrackerSpy(),
                         file: StaticString = #filePath,
                         line: UInt = #line) -> StoryCameraViewModel {
        let camera = CameraSpy()
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
        
        func getPublisher() -> AnyPublisher<Bool, Never> {
            authorizationPublisher.eraseToAnyPublisher()
        }
        
        func startTracking() {
            
        }
        
        func publish(permissionGranted: Bool) {
            authorizationPublisher.send(permissionGranted)
        }
    }
    
    private class CameraSpy: Camera {
        var cameraPosition = CameraPosition.back
        
        var videoPreviewLayer: CALayer {
            CALayer()
        }
        
        func getStatusPublisher() -> AnyPublisher<CameraStatus, Never> {
            Empty().eraseToAnyPublisher()
        }
        
        func startSession() {
            
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

extension DispatchQueue {
    static var immediateWhenOnMainQueueScheduler: ImmediateWhenOnMainQueueScheduler {
        .shared
    }
    
    struct ImmediateWhenOnMainQueueScheduler: Scheduler {
        typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
        typealias SchedulerOptions = DispatchQueue.SchedulerOptions
        
        static let shared = Self()
        
        private static let key = DispatchSpecificKey<UInt8>()
        private static let value = UInt8.max
        
        private init() {
            DispatchQueue.main.setSpecific(key: Self.key, value: Self.value)
        }
        
        var now: SchedulerTimeType {
            DispatchQueue.main.now
        }
        
        var minimumTolerance: SchedulerTimeType.Stride {
            DispatchQueue.main.minimumTolerance
        }
        
        func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
            guard isMainQueue() else {
                DispatchQueue.main.schedule(options: options, action)
                return
            }
            
            action()
        }
        
        private func isMainQueue() -> Bool {
            DispatchQueue.getSpecific(key: Self.key) == Self.value
        }
        
        func schedule(after date: SchedulerTimeType, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
            DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: options, action)
        }
        
        func schedule(after date: SchedulerTimeType, interval: SchedulerTimeType.Stride, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
            DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: options, action)
        }
    }
}
