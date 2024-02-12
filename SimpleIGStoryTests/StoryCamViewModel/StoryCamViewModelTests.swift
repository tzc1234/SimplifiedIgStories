//
//  StoryCamViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 16/07/2022.
//

import XCTest
import Combine
@testable import Simple_IG_Story

@MainActor class StoryCamViewModelTests: XCTestCase {

    var camManager: MockCamManager!
    var sut: StoryCamViewModel!
    var subscriptions: Set<AnyCancellable>!
    
    @MainActor override func setUpWithError() throws {
        camManager = MockCamManager()
        sut = StoryCamViewModel(camManager: camManager)
        subscriptions = Set<AnyCancellable>()
    }

    @MainActor override func tearDownWithError() throws {
        camManager = nil
        sut = nil
        subscriptions = nil
    }
    
    func test_checkPermissions_permissionsAreNotGranted_beforeFunctionCalled() {
        XCTAssertFalse(sut.isCamPermGranted, "camera permission")
        XCTAssertFalse(sut.isMicrophonePermGranted, "microphone permission")
        XCTAssertFalse(sut.arePermissionsGranted, "both permissions")
    }
    
    func test_checkPermissions_permissionGranted_afterFunctionCalled() {
        let cameraAuthorizationTrackerStub = DeviceAuthorizationTrackerStub()
        let microphoneAuthorizationTrackerStub = DeviceAuthorizationTrackerStub()
        let sut = makeSUT(
            cameraAuthorizationTracker: cameraAuthorizationTrackerStub,
            microphoneAuthorizationTracker: microphoneAuthorizationTrackerStub
        )
        
        let expectation = XCTestExpectation(description: "should receive permissions from publishers")
        
        sut.$isCamPermGranted.zip(sut.$isMicrophonePermGranted)
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.checkPermissions()
        cameraAuthorizationTrackerStub.setAuthorized(true)
        microphoneAuthorizationTrackerStub.setAuthorized(true)
        
        wait(for: [expectation], timeout: 0.1)
        
        XCTAssertTrue(sut.isCamPermGranted, "camera permission")
        XCTAssertTrue(sut.isMicrophonePermGranted, "microphone permission")
        XCTAssertTrue(sut.arePermissionsGranted, "both permissions")
    }
    
    func test_videoPreviewLayer_returnTheSameLayerAsCamManagerVideoPreviewLayer() {
        XCTAssertIdentical(sut.videoPreviewLayer, camManager.videoPreviewLayer)
    }

    func test_setupAndStartSession_enableVideoRecordBtnShouldBeFalse_beforeFunctionCalled() {
        XCTAssertFalse(sut.enableVideoRecordBtn, "enableVideoRecordBtn")
        XCTAssertEqual(camManager.setupAndStartSessionCallCount, 0, "setupAndStartSessionCallCount")
    }
    
    func test_setupAndStartSession_enableVideoRecordBtnShouldBeTrueAndSessionShouldBeStarted_afterFunctionCalled() {
        let camStatusPublisherExpectation = XCTestExpectation(description: "should receive status from camStatusPublisher")
        let enableVideoRecordBtnExpectation = XCTestExpectation(description: "should receive enableVideoRecordBtn value")
        
        camManager.camStatusPublisher
            .sink { status in
                switch status {
                case .sessionStarted:
                    break
                default:
                    XCTFail("should receive .sessionStarted status")
                }
                
                camStatusPublisherExpectation.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.$enableVideoRecordBtn
            .dropFirst()
            .sink { _ in
                enableVideoRecordBtnExpectation.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.setupAndStartSession()
        
        wait(for: [camStatusPublisherExpectation, enableVideoRecordBtnExpectation], timeout: 0.1)
        
        XCTAssertTrue(sut.enableVideoRecordBtn, "enableVideoRecordBtn")
        XCTAssertEqual(camManager.setupAndStartSessionCallCount, 1, "setupAndStartSessionCallCount")
    }
    
    func test_switchCamera_camPositionShouldBeBack_beforeFuctionCalled() {
        XCTAssertEqual(camManager.switchCameraCallCount, 0, "switchCameraCallCount")
        XCTAssertEqual(camManager.camPosition, .back, "camPosition")
    }
    
    func test_switchCamera_shouldReceiveCameraSwitchedStatus_afterFuctionCalled() {
        camManager.camStatusPublisher
            .sink { status in
                switch status {
                case .cameraSwitched:
                    break
                default:
                    XCTFail("should receive .cameraSwitched status")
                }
            }
            .store(in: &subscriptions)
        
        sut.switchCamera()
        
        XCTAssertEqual(camManager.switchCameraCallCount, 1, "switchCameraCallCount")
        XCTAssertEqual(camManager.camPosition, .front, "camPosition")
    }
    
    func test_flashMode_flashModeShouldBeOff_afterInital() {
        XCTAssertEqual(sut.flashMode, .off, "vm.flashMode")
        XCTAssertEqual(sut.flashMode, camManager.flashMode, "vm.flashMode == camManager.flashMode")
    }
    
    func test_flashMode_flashModeValueShouldBeChanged_afterAssignNewValueToFlashMode() {
        sut.flashMode = .on
        
        XCTAssertEqual(sut.flashMode, .on, "vm.flashMode")
        XCTAssertEqual(sut.flashMode, camManager.flashMode, "vm.flashMode == camManager.flashMode")
        
        sut.flashMode = .auto
        
        XCTAssertEqual(sut.flashMode, .auto, "vm.flashMode")
        XCTAssertEqual(sut.flashMode, camManager.flashMode, "vm.flashMode == camManager.flashMode")
        
        sut.flashMode = .off
        
        XCTAssertEqual(sut.flashMode, .off, "vm.flashMode")
        XCTAssertEqual(sut.flashMode, camManager.flashMode, "vm.flashMode == camManager.flashMode")
    }
    
    func test_shouldPhotoTake_shouldPhotoTakeShouldBeFalse_afterInital() {
        XCTAssertFalse(sut.shouldPhotoTake, "shouldPhotoTake")
        XCTAssertFalse(sut.showPhotoPreview, "showPhotoPreview")
        XCTAssertNil(sut.lastTakenImage, "lastTakenImage")
    }
    
    func test_shouldPhotoTake_showPhotoPreviewShouldBeTrueAndLastTakenImageNotNil_afterShouldPhotoTakeSetToTrue() {
        let expection = XCTestExpectation(description: "should received showPhotoPreview")
        
        sut.$showPhotoPreview
            .dropFirst()
            .sink { _ in
                expection.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.shouldPhotoTake = true
        
        wait(for: [expection], timeout: 0.1)
        
        XCTAssertTrue(sut.shouldPhotoTake, "shouldPhotoTake")
        XCTAssertTrue(sut.showPhotoPreview, "showPhotoPreview")
        XCTAssertEqual(camManager.takePhotoCallCount, 1, "takePhotoCallCount")
        XCTAssertEqual(camManager.stopSessionCallCount, 1, "stopSessionCallCount")
        XCTAssertNotNil(sut.lastTakenImage, "lastTakenImage")
        XCTAssertEqual(sut.lastTakenImage, camManager.lastPhoto, "vm.lastTakenImage == camManager.lastPhoto")
    }
    
    func test_showPhotoPreview_startSessionShouldBeCalled_whenShowPhotoPreviewSetToFalse() {
        sut.showPhotoPreview = false
        
        XCTAssertFalse(sut.showPhotoPreview, "showPhotoPreview")
        XCTAssertEqual(camManager.startSessionCallCount, 1, "startSessionCallCount")
    }
    
    func test_videoRecordingStatus_videoRecordingStatusShouldBeNone_afterInital() {
        XCTAssertEqual(sut.videoRecordingStatus, .none, "videoRecordingStatus")
        XCTAssertNil(sut.lastVideoUrl, "lastVideoUrl")
        XCTAssertFalse(sut.showVideoPreview, "showVideoPreview")
    }
    
    func test_videoRecordingStatus_videoRecordingStatusChanges() {
        let startVideoRecordingStatusExpection = XCTestExpectation(description: "Should received VideoRecordingStatus.start")
        let stopVideoRecordingStatusExpection = XCTestExpectation(description: "Should received VideoRecordingStatus.stop")
        let noneVideoRecordingStatusExpection = XCTestExpectation(description: "Should received VideoRecordingStatus.none")
        
        sut.$videoRecordingStatus
            .dropFirst()
            .sink { status in
                switch status {
                case .none:
                    noneVideoRecordingStatusExpection.fulfill()
                case .start:
                    startVideoRecordingStatusExpection.fulfill()
                case .stop:
                    stopVideoRecordingStatusExpection.fulfill()
                }
            }
            .store(in: &subscriptions)
        
        sut.videoRecordingStatus = .start
        
        wait(for: [startVideoRecordingStatusExpection], timeout: 0.1)
        
        XCTAssertEqual(sut.videoRecordingStatus, .start, "videoRecordingStatus")
        XCTAssertNil(sut.lastVideoUrl, "lastVideoUrl")
        XCTAssertFalse(sut.showVideoPreview, "showVideoPreview")
        
        sut.videoRecordingStatus = .stop
        
        wait(for: [stopVideoRecordingStatusExpection], timeout: 0.1)
        
        XCTAssertEqual(sut.videoRecordingStatus, .stop, "videoRecordingStatus")
        XCTAssertNil(sut.lastVideoUrl, "lastVideoUrl")
        XCTAssertFalse(sut.showVideoPreview, "showVideoPreview")
        
        camManager.finishVideoProcessing()
        
        wait(for: [noneVideoRecordingStatusExpection], timeout: 0.1)
        
        XCTAssertEqual(sut.videoRecordingStatus, .none, "videoRecordingStatus")
        XCTAssertNotNil(sut.lastVideoUrl, "lastVideoUrl")
        XCTAssertTrue(sut.showVideoPreview, "showVideoPreview")
        XCTAssertEqual(sut.lastVideoUrl, camManager.lastVideoUrl, "vm.lastVideoUrl == camManager.lastVideoUrl")
        
        XCTAssertEqual(camManager.startVideoRecordingCallCount, 1, "startVideoRecordingCallCount")
        XCTAssertEqual(camManager.stopVideoRecordingCallCount, 1, "stopVideoRecordingCallCount")
    }
    
    func test_showVideoPreview_startSessionShouldBeCalled_whenShowVideoPreviewSetToFalse() {
        sut.showVideoPreview = false
        
        XCTAssertFalse(sut.showVideoPreview, "showVideoPreview")
        XCTAssertEqual(camManager.startSessionCallCount, 1, "startSessionCallCount")
    }
    
    func test_videoPreviewTapPoint_videoPreviewTapPointShouldBeZero_afterInital() {
        XCTAssertEqual(sut.videoPreviewTapPoint, .zero)
    }
    
    func test_videoPreviewTapPoint_videoPreviewTapPointChanged_afterNewPointAssigned() {
        let point = CGPoint(x: CGFloat.random(in: 1...99), y: CGFloat.random(in: 1...99))
        sut.videoPreviewTapPoint = point
        
        XCTAssertEqual(sut.videoPreviewTapPoint, point, "videoPreviewTapPoint")
        XCTAssertEqual(sut.videoPreviewTapPoint, camManager.focusPoint, "vm.videoPreviewTapPoint == camManager.focusPoint")
    }
    
    func test_videoPreviewPinchFactor_videoPreviewPinchFactorShouldBeZero_afterInital() {
        XCTAssertEqual(sut.videoPreviewPinchFactor, .zero)
    }
    
    func test_videoPreviewPinchFactor_videoPreviewPinchFactorChanged_afterNewFactorAssigned() {
        let factor = CGFloat.random(in: 1...99)
        sut.videoPreviewPinchFactor = factor
        
        XCTAssertEqual(sut.videoPreviewPinchFactor, factor, "videoPreviewPinchFactor")
        XCTAssertEqual(sut.videoPreviewPinchFactor, camManager.zoomFactor, "vm.videoPreviewPinchFactor == camManager.zoomFactor")
    }
    
    // MARK: Helpers
    
    private func makeSUT(cameraAuthorizationTracker: DeviceAuthorizationTracker = DeviceAuthorizationTrackerStub(),
                         microphoneAuthorizationTracker: DeviceAuthorizationTracker = DeviceAuthorizationTrackerStub()) 
    -> StoryCamViewModel {
        let camManager = MockCamManager()
        let sut = StoryCamViewModel(
            camManager: camManager,
            cameraAuthorizationTracker: cameraAuthorizationTracker,
            microphoneAuthorizationTracker: microphoneAuthorizationTracker
        )
        return sut
    }
    
    private class DeviceAuthorizationTrackerStub: DeviceAuthorizationTracker {
        private let publisher = CurrentValueSubject<Bool, Never>(false)
        
        func getPublisher() -> AnyPublisher<Bool, Never> {
            publisher.eraseToAnyPublisher()
        }
        
        func startTracking() {}
        
        func setAuthorized(_ authorized: Bool) {
            publisher.send(authorized)
        }
    }
}
