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

    var camManager: FakeCamManager!
    var vm: StoryCamViewModel!
    var subscriptions: Set<AnyCancellable>!
    
    @MainActor override func setUpWithError() throws {
        camManager = FakeCamManager()
        vm = StoryCamViewModel(camManager: camManager)
        subscriptions = Set<AnyCancellable>()
    }

    @MainActor override func tearDownWithError() throws {
        camManager = nil
        vm = nil
        subscriptions = nil
    }
    
    func test_checkPermissions_permissionsAreNotGranted_beforeFunctionCalled() {
        XCTAssertFalse(vm.isCamPermGranted, "camera permission")
        XCTAssertFalse(vm.isMicrophonePermGranted, "microphone permission")
        XCTAssertFalse(vm.arePermissionsGranted, "both permissions")
    }
    
    func test_checkPermissions_permissionGranted_afterFunctionCalled() {
        let expectation = XCTestExpectation(description: "should receive permissions from publishers")
        
        vm.$isCamPermGranted.zip(vm.$isMicrophonePermGranted)
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        
        vm.checkPermissions()
        
        wait(for: [expectation], timeout: 0.1)
        
        XCTAssertTrue(vm.isCamPermGranted, "camera permission")
        XCTAssertTrue(vm.isMicrophonePermGranted, "microphone permission")
        XCTAssertTrue(vm.arePermissionsGranted, "both permission")
    }
    
    func test_videoPreviewLayer_returnTheSameLayerAsCamManagerVideoPreviewLayer() {
        XCTAssertIdentical(vm.videoPreviewLayer, camManager.videoPreviewLayer)
    }

    func test_setupAndStartSession_enableVideoRecordBtnShouldBeFalse_beforeFunctionCalled() {
        XCTAssertFalse(vm.enableVideoRecordBtn, "enableVideoRecordBtn")
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
        
        vm.$enableVideoRecordBtn
            .dropFirst()
            .sink { _ in
                enableVideoRecordBtnExpectation.fulfill()
            }
            .store(in: &subscriptions)
        
        vm.setupAndStartSession()
        
        wait(for: [camStatusPublisherExpectation, enableVideoRecordBtnExpectation], timeout: 0.1)
        
        XCTAssertTrue(vm.enableVideoRecordBtn, "enableVideoRecordBtn")
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
        
        vm.switchCamera()
        
        XCTAssertEqual(camManager.switchCameraCallCount, 1, "switchCameraCallCount")
        XCTAssertEqual(camManager.camPosition, .front, "camPosition")
    }
    
    func test_flashMode_flashModeShouldBeOff_afterInital() {
        XCTAssertEqual(vm.flashMode, .off, "vm.flashMode")
        XCTAssertEqual(vm.flashMode, camManager.flashMode, "vm.flashMode == camManager.flashMode")
    }
    
    func test_flashMode_flashModeValueShouldBeChanged_afterAssignNewValueToFlashMode() {
        vm.flashMode = .on
        
        XCTAssertEqual(vm.flashMode, .on, "vm.flashMode")
        XCTAssertEqual(vm.flashMode, camManager.flashMode, "vm.flashMode == camManager.flashMode")
        
        vm.flashMode = .auto
        
        XCTAssertEqual(vm.flashMode, .auto, "vm.flashMode")
        XCTAssertEqual(vm.flashMode, camManager.flashMode, "vm.flashMode == camManager.flashMode")
        
        vm.flashMode = .off
        
        XCTAssertEqual(vm.flashMode, .off, "vm.flashMode")
        XCTAssertEqual(vm.flashMode, camManager.flashMode, "vm.flashMode == camManager.flashMode")
    }
    
    func test_shouldPhotoTake_shouldPhotoTakeShouldBeFalse_afterInital() {
        XCTAssertFalse(vm.shouldPhotoTake, "shouldPhotoTake")
        XCTAssertFalse(vm.showPhotoPreview, "showPhotoPreview")
        XCTAssertNil(vm.lastTakenImage, "lastTakenImage")
    }
    
    func test_shouldPhotoTake_showPhotoPreviewShouldBeTrueAndLastTakenImageNotNil_afterShouldPhotoTakeSetToTrue() {
        let expection = XCTestExpectation(description: "should received showPhotoPreview")
        
        vm.$showPhotoPreview
            .dropFirst()
            .sink { _ in
                expection.fulfill()
            }
            .store(in: &subscriptions)
        
        vm.shouldPhotoTake = true
        
        wait(for: [expection], timeout: 0.1)
        
        XCTAssertTrue(vm.shouldPhotoTake, "shouldPhotoTake")
        XCTAssertTrue(vm.showPhotoPreview, "showPhotoPreview")
        XCTAssertEqual(camManager.takePhotoCallCount, 1, "takePhotoCallCount")
        XCTAssertEqual(camManager.stopSessionCallCount, 1, "stopSessionCallCount")
        XCTAssertNotNil(vm.lastTakenImage, "lastTakenImage")
        XCTAssertEqual(vm.lastTakenImage, camManager.lastPhoto, "vm.lastTakenImage == camManager.lastPhoto")
    }
    
    func test_showPhotoPreview_startSessionShouldBeCalled_whenShowPhotoPreviewSetToFalse() {
        vm.showPhotoPreview = false
        
        XCTAssertFalse(vm.showPhotoPreview, "showPhotoPreview")
        XCTAssertEqual(camManager.startSessionCallCount, 1, "startSessionCallCount")
    }
    
    func test_videoRecordingStatus_videoRecordingStatusShouldBeNone_afterInital() {
        XCTAssertEqual(vm.videoRecordingStatus, .none, "videoRecordingStatus")
        XCTAssertNil(vm.lastVideoUrl, "lastVideoUrl")
        XCTAssertFalse(vm.showVideoPreview, "showVideoPreview")
    }
    
    func test_videoRecordingStatus_videoRecordingStatusChanges() {
        let startVideoRecordingStatusExpection = XCTestExpectation(description: "Should received VideoRecordingStatus.start")
        let stopVideoRecordingStatusExpection = XCTestExpectation(description: "Should received VideoRecordingStatus.stop")
        let noneVideoRecordingStatusExpection = XCTestExpectation(description: "Should received VideoRecordingStatus.none")
        
        vm.$videoRecordingStatus
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
        
        vm.videoRecordingStatus = .start
        
        wait(for: [startVideoRecordingStatusExpection], timeout: 0.1)
        
        XCTAssertEqual(vm.videoRecordingStatus, .start, "videoRecordingStatus")
        XCTAssertNil(vm.lastVideoUrl, "lastVideoUrl")
        XCTAssertFalse(vm.showVideoPreview, "showVideoPreview")
        
        vm.videoRecordingStatus = .stop
        
        wait(for: [stopVideoRecordingStatusExpection], timeout: 0.1)
        
        XCTAssertEqual(vm.videoRecordingStatus, .stop, "videoRecordingStatus")
        XCTAssertNil(vm.lastVideoUrl, "lastVideoUrl")
        XCTAssertFalse(vm.showVideoPreview, "showVideoPreview")
        
        camManager.finishVideoProcessing()
        
        wait(for: [noneVideoRecordingStatusExpection], timeout: 0.1)
        
        XCTAssertEqual(vm.videoRecordingStatus, .none, "videoRecordingStatus")
        XCTAssertNotNil(vm.lastVideoUrl, "lastVideoUrl")
        XCTAssertTrue(vm.showVideoPreview, "showVideoPreview")
        XCTAssertEqual(vm.lastVideoUrl, camManager.lastVideoUrl, "vm.lastVideoUrl == camManager.lastVideoUrl")
        
        XCTAssertEqual(camManager.startVideoRecordingCallCount, 1, "startVideoRecordingCallCount")
        XCTAssertEqual(camManager.stopVideoRecordingCallCount, 1, "stopVideoRecordingCallCount")
    }
    
    func test_showVideoPreview_startSessionShouldBeCalled_whenShowVideoPreviewSetToFalse() {
        vm.showVideoPreview = false
        
        XCTAssertFalse(vm.showVideoPreview, "showVideoPreview")
        XCTAssertEqual(camManager.startSessionCallCount, 1, "startSessionCallCount")
    }
    
    func test_videoPreviewTapPoint_videoPreviewTapPointShouldBeZero_afterInital() {
        XCTAssertEqual(vm.videoPreviewTapPoint, .zero)
    }
    
    func test_videoPreviewTapPoint_videoPreviewTapPointChanged_afterNewPointAssigned() {
        let point = CGPoint(x: CGFloat.random(in: 1...99), y: CGFloat.random(in: 1...99))
        vm.videoPreviewTapPoint = point
        
        XCTAssertEqual(vm.videoPreviewTapPoint, point, "videoPreviewTapPoint")
        XCTAssertEqual(vm.videoPreviewTapPoint, camManager.focusPoint, "vm.videoPreviewTapPoint == camManager.focusPoint")
    }
    
    func test_videoPreviewPinchFactor_videoPreviewPinchFactorShouldBeZero_afterInital() {
        XCTAssertEqual(vm.videoPreviewPinchFactor, .zero)
    }
    
    func test_videoPreviewPinchFactor_videoPreviewPinchFactorChanged_afterNewFactorAssigned() {
        let factor = CGFloat.random(in: 1...99)
        vm.videoPreviewPinchFactor = factor
        
        XCTAssertEqual(vm.videoPreviewPinchFactor, factor, "videoPreviewPinchFactor")
        XCTAssertEqual(vm.videoPreviewPinchFactor, camManager.zoomFactor, "vm.videoPreviewPinchFactor == camManager.zoomFactor")
    }
}
