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
    
    func test_StoryCamViewModel_checkPermissions_permissionGranted_afterFunctionCalled() {
        XCTAssertFalse(camManager.camPermPublisher.value)
        XCTAssertFalse(camManager.microphonePermPublisher.value)
        XCTAssertFalse(vm.isCamPermGranted)
        XCTAssertFalse(vm.isMicrophonePermGranted)
        XCTAssertFalse(vm.arePermissionsGranted)
        
        let expectation = XCTestExpectation(description: "Should receive permissions from publishers within 3s.")
        
        vm.$isCamPermGranted.zip(vm.$isMicrophonePermGranted)
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        
        vm.checkPermissions()
        
        wait(for: [expectation], timeout: 3)
        
        XCTAssertTrue(camManager.camPermPublisher.value)
        XCTAssertTrue(camManager.microphonePermPublisher.value)
        XCTAssertTrue(vm.isCamPermGranted)
        XCTAssertTrue(vm.isMicrophonePermGranted)
        XCTAssertTrue(vm.arePermissionsGranted)
    }
    
    func test_StoryCamViewModel_videoPreviewLayer_returnTheSameLayerAsCamManagerVideoPreviewLayer() {
        XCTAssertEqual(vm.videoPreviewLayer, camManager.videoPreviewLayer)
    }

    func test_StoryCamViewModel_setupAndStartSession_sessionShouldBeStartedAfterCalled() {
        XCTAssertFalse(vm.enableVideoRecordBtn)
        XCTAssertFalse(camManager.setupAndStartSessionCalled)
        
        let camStatusPublisherExpectation = XCTestExpectation(description: "Should receive status from camStatusPublisher within 3s.")
        let enableVideoRecordBtnExpectation = XCTestExpectation(description: "Should receive enableVideoRecordBtn value within 3s.")
        
        camManager.camStatusPublisher
            .sink { status in
                switch status {
                case .sessionStarted:
                    break
                default:
                    XCTFail("Should receive .sessionStarted status.")
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
        
        wait(for: [camStatusPublisherExpectation, enableVideoRecordBtnExpectation], timeout: 3)
        
        XCTAssertTrue(camManager.setupAndStartSessionCalled)
        XCTAssertTrue(vm.enableVideoRecordBtn)
    }
    
    func test_StoryCamViewModel_switchCamera_shouldReceiveCameraSwitchedStatusAfterFuctionCalled() {
        XCTAssertFalse(camManager.switchCameraCalled)
        XCTAssertEqual(camManager.camPosition, .back)
        
        camManager.camStatusPublisher
            .sink { status in
                switch status {
                case .cameraSwitched:
                    break
                default:
                    XCTFail("Should receive .sessionStarted status.")
                }
            }
            .store(in: &subscriptions)
        
        vm.switchCamera()
        
        XCTAssertTrue(camManager.switchCameraCalled)
        XCTAssertEqual(camManager.camPosition, .front)
    }
    
    func test_StoryCamViewModel_flashMode_updateFlashMode() {
        XCTAssertEqual(vm.flashMode, .off)
        XCTAssertEqual(camManager.flashMode, .off)
        
        vm.flashMode = .on
        
        XCTAssertEqual(vm.flashMode, .on)
        XCTAssertEqual(camManager.flashMode, .on)
        XCTAssertEqual(camManager.flashMode, vm.flashMode)
    }
    
    func test_StoryCamViewModel_shouldPhotoTake_changeShouldPhotoTakeValue() {
        XCTAssertFalse(vm.shouldPhotoTake)
        XCTAssertFalse(vm.showPhotoPreview)
        XCTAssertFalse(camManager.takePhotoCalled)
        XCTAssertFalse(camManager.stopSessionCalled)
        XCTAssertNil(camManager.lastPhoto)
        XCTAssertNil(vm.lastTakenImage)
        
        let expection = XCTestExpectation(description: "Should received showPhotoPreview within 3s.")
        
        vm.$showPhotoPreview
            .dropFirst()
            .sink { _ in
                expection.fulfill()
            }
            .store(in: &subscriptions)
        
        vm.shouldPhotoTake = true
        
        wait(for: [expection], timeout: 3)
        
        XCTAssertTrue(vm.shouldPhotoTake)
        XCTAssertTrue(vm.showPhotoPreview)
        XCTAssertTrue(camManager.takePhotoCalled)
        XCTAssertTrue(camManager.stopSessionCalled)
        XCTAssertNotNil(camManager.lastPhoto)
        XCTAssertNotNil(vm.lastTakenImage)
        XCTAssertEqual(camManager.lastPhoto, vm.lastTakenImage)
    }
    
    func test_StoryCamViewModel_videoRecordingStatus_videoRecording() {
        XCTAssertEqual(vm.videoRecordingStatus, .none)
        XCTAssertFalse(camManager.startVideoRecordingCalled)
        XCTAssertNil(vm.lastVideoUrl)
        XCTAssertFalse(vm.showVideoPreview)
        
        let startVideoRecordingStatusExpection = XCTestExpectation(description: "Should received VideoRecordingStatus.start within 3s.")
        let stopVideoRecordingStatusExpection = XCTestExpectation(description: "Should received VideoRecordingStatus.stop within 3s.")
        let noneVideoRecordingStatusExpection = XCTestExpectation(description: "Should received VideoRecordingStatus.none within 3s.")
        
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
        
        wait(for: [startVideoRecordingStatusExpection], timeout: 3)
        
        XCTAssertEqual(vm.videoRecordingStatus, .start)
        XCTAssertTrue(camManager.startVideoRecordingCalled)
        XCTAssertFalse(camManager.stopVideoRecordingCalled)
        XCTAssertNil(vm.lastVideoUrl)
        XCTAssertFalse(vm.showVideoPreview)
        
        vm.videoRecordingStatus = .stop
        
        wait(for: [stopVideoRecordingStatusExpection], timeout: 3)
        
        XCTAssertEqual(vm.videoRecordingStatus, .stop)
        XCTAssertTrue(camManager.stopVideoRecordingCalled)
        XCTAssertNil(vm.lastVideoUrl)
        XCTAssertFalse(vm.showVideoPreview)
        
        camManager.finishVideoProcessing()
        
        wait(for: [noneVideoRecordingStatusExpection], timeout: 3)
        
        XCTAssertEqual(vm.videoRecordingStatus, .none)
        XCTAssertNotNil(vm.lastVideoUrl)
        XCTAssertTrue(vm.showVideoPreview)
        XCTAssertEqual(vm.lastVideoUrl, camManager.lastVideoUrl)
    }
    
    func test_StoryCamViewModel_videoPreviewTapPoint_updateVideoPreviewTapPoint() {
        XCTAssertNil(camManager.focusPoint)
        XCTAssertEqual(vm.videoPreviewTapPoint, .zero)
        
        let point = CGPoint(x: CGFloat.random(in: 1...99), y: CGFloat.random(in: 1...99))
        vm.videoPreviewTapPoint = point
        
        XCTAssertEqual(vm.videoPreviewTapPoint, point)
        XCTAssertEqual(vm.videoPreviewTapPoint, camManager.focusPoint)
    }
    
    func test_StoryCamViewModel_videoPreviewPinchFactor_updateVideoPreviewPinchFactor() {
        XCTAssertNil(camManager.zoomFactor)
        XCTAssertEqual(vm.videoPreviewPinchFactor, .zero)
        
        let factor = CGFloat.random(in: 1...99)
        vm.videoPreviewPinchFactor = factor
        
        XCTAssertEqual(vm.videoPreviewPinchFactor, factor)
        XCTAssertEqual(vm.videoPreviewPinchFactor, camManager.zoomFactor)
    }
}
