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
    
    @MainActor
    func test_showPreview_stopsSessionOnCameraWhenShowPreview() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        
        XCTAssertEqual(camera.stopSessionCallCount, 0)
        
        sut.showPreview = true
        
        XCTAssertEqual(camera.stopSessionCallCount, 1)
    }
    
    @MainActor
    func test_showPreview_startsSessionOnCameraWhenNotShowPreview() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        
        XCTAssertEqual(camera.startSessionCallCount, 0)
        
        sut.showPreview = false
        
        XCTAssertEqual(camera.startSessionCallCount, 1)
    }
    
    @MainActor
    func test_isVideoRecording_stopsRecordingOnCameraWhenVideoRecording() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        
        XCTAssertEqual(camera.stopRecordingCallCount, 0)
        
        sut.isVideoRecording = false
        
        XCTAssertEqual(camera.stopRecordingCallCount, 1)
    }
    
    @MainActor
    func test_isVideoRecording_startsRecordingOnCameraWhenVideoRecording() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        
        XCTAssertEqual(camera.startRecordingCallCount, 0)
        
        sut.isVideoRecording = true
        
        XCTAssertEqual(camera.startRecordingCallCount, 1)
    }
    
    @MainActor
    func test_switchCamera_switchesCameraOnCamera() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        
        XCTAssertEqual(camera.switchCameraCallCount, 0)
        
        sut.switchCamera()
        
        XCTAssertEqual(camera.switchCameraCallCount, 1)
    }
    
    @MainActor
    func test_takePhoto_takesPhotoOnCameraWithFlashMode() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        
        XCTAssertEqual(camera.loggedFlashModes, [])
        
        sut.flashMode = .auto
        sut.takePhoto()
        
        XCTAssertEqual(camera.loggedFlashModes, [.auto])
        
        sut.flashMode = .on
        sut.takePhoto()
        
        XCTAssertEqual(camera.loggedFlashModes, [.auto, .on])
        
        sut.flashMode = .off
        sut.takePhoto()
        
        XCTAssertEqual(camera.loggedFlashModes, [.auto, .on, .off])
    }
    
    @MainActor
    func test_focus_setFocusOnCamera() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        let focusPoint = CGPoint(x: 999, y: 999)
        
        XCTAssertEqual(camera.loggedFocusPoints, [])
        
        sut.focus(on: focusPoint)
        
        XCTAssertEqual(camera.loggedFocusPoints, [focusPoint])
    }
    
    @MainActor
    func test_zoom_zoomsOnCamera() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        let zoomFactor = CGFloat(999)
        
        XCTAssertEqual(camera.loggedZoomFactors, [])
        
        sut.zoom(to: zoomFactor)
        
        XCTAssertEqual(camera.loggedZoomFactors, [zoomFactor])
    }
    
    @MainActor
    func test_enableVideoRecordButton_configuresVideoRecordBtnOnCameraSessionStatus() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        
        XCTAssertFalse(sut.enableVideoRecordButton)
        
        camera.publish(status: .sessionStarted)
        
        XCTAssertTrue(sut.enableVideoRecordButton)
        
        camera.publish(status: .sessionStopped)
        
        XCTAssertFalse(sut.enableVideoRecordButton)
    }
    
    @MainActor
    func test_media_deliversImageReceivedFromCameraPhotoTakenStatus() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        let expectedImage = UIImage.make(withColor: .gray)
        
        XCTAssertNil(sut.media)
        XCTAssertFalse(sut.showPreview)
        
        camera.publish(status: .processedMedia(.image(expectedImage)))
        
        if case let .image(image) = sut.media {
            XCTAssertEqual(image, expectedImage)
            XCTAssertTrue(sut.showPreview)
        } else {
            XCTFail("Image should not be nil")
        }
    }
    
    @MainActor
    func test_isVideoRecording_resetsIsVideoRecordingOnCameraRecordingFinishedStatus() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        
        sut.isVideoRecording = true
        
        XCTAssertNotNil(sut.isVideoRecording)
        
        camera.publish(status: .recordingFinished)
        
        XCTAssertNil(sut.isVideoRecording)
    }
    
    @MainActor
    func test_lastVideoURL_deliversVideoURLReceivedFromCameraProcessedVideoStatus() {
        let camera = CameraSpy()
        let sut = makeSUT(camera: camera)
        let expectedVideoURL = anyVideoURL()
        
        XCTAssertNil(sut.media)
        XCTAssertFalse(sut.showPreview)
        
        camera.publish(status: .processedMedia(.video(expectedVideoURL)))
        
        if case let .video(url) = sut.media {
            XCTAssertEqual(url, expectedVideoURL)
            XCTAssertTrue(sut.showPreview)
        } else {
            XCTFail("VideoURL should not be nil")
        }
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
}
