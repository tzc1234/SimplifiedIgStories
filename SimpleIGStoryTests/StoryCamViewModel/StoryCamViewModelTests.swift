//
//  StoryCamViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 16/07/2022.
//

import XCTest
import Combine
@testable import Simple_IG_Story

@MainActor 
class StoryCamViewModelTests: XCTestCase {
    var subscriptions: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        subscriptions = Set<AnyCancellable>()
    }

    override func tearDown() {
        super.tearDown()
        
        subscriptions = nil
    }
    
    func test_checkPermissions_permissionsAreNotGranted_beforeFunctionCalled() {
        let (sut, _) = makeSUT()
        
        XCTAssertFalse(sut.isCamPermGranted, "camera permission")
        XCTAssertFalse(sut.isMicrophonePermGranted, "microphone permission")
        XCTAssertFalse(sut.arePermissionsGranted, "both permissions")
    }
    
    func test_checkPermissions_permissionGranted_afterFunctionCalled() {
        let cameraAuthorizationTrackerStub = DeviceAuthorizationTrackerStub()
        let microphoneAuthorizationTrackerStub = DeviceAuthorizationTrackerStub()
        let (sut, _) = makeSUT(
            cameraAuthorizationTracker: cameraAuthorizationTrackerStub,
            microphoneAuthorizationTracker: microphoneAuthorizationTrackerStub
        )
        
        let exp = XCTestExpectation(description: "should receive permissions from publishers")
        sut.$isCamPermGranted.zip(sut.$isMicrophonePermGranted)
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.checkPermissions()
        cameraAuthorizationTrackerStub.setAuthorized(true)
        microphoneAuthorizationTrackerStub.setAuthorized(true)
        
        wait(for: [exp], timeout: 0.1)
        
        XCTAssertTrue(sut.isCamPermGranted, "camera permission")
        XCTAssertTrue(sut.isMicrophonePermGranted, "microphone permission")
        XCTAssertTrue(sut.arePermissionsGranted, "both permissions")
    }
    
    func test_videoPreviewLayer_returnTheSameLayerAsCamManagerVideoPreviewLayer() {
        let (sut, camManager) = makeSUT()
        
        XCTAssertIdentical(sut.videoPreviewLayer, camManager.videoPreviewLayer)
    }

    func test_setupAndStartSession_enableVideoRecordBtnShouldBeFalse_beforeFunctionCalled() {
        let (sut, camManager) = makeSUT()
        
        XCTAssertFalse(sut.enableVideoRecordBtn, "enableVideoRecordBtn")
        XCTAssertEqual(camManager.setupAndStartSessionCallCount, 0, "setupAndStartSessionCallCount")
    }
    
    func test_setupAndStartSession_enableVideoRecordBtnShouldBeTrueAndSessionShouldBeStarted_afterFunctionCalled() {
        let (sut, camManager) = makeSUT()
        
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
    
    func test_switchCamera_camPositionShouldBeBack_beforeFunctionCalled() {
        let (_, camManager) = makeSUT()
        
        XCTAssertEqual(camManager.switchCameraCallCount, 0, "switchCameraCallCount")
        XCTAssertEqual(camManager.cameraPosition, .back, "camPosition")
    }
    
    func test_switchCamera_shouldReceiveCameraSwitchedStatus_afterFunctionCalled() {
        let (sut, camManager) = makeSUT()
        
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
        XCTAssertEqual(camManager.cameraPosition, .front, "camPosition")
    }
    
    func test_shouldPhotoTake_shouldPhotoTakeShouldBeFalse_afterInitial() {
        let (sut, _) = makeSUT()
        
        XCTAssertFalse(sut.shouldPhotoTake, "shouldPhotoTake")
        XCTAssertFalse(sut.showPhotoPreview, "showPhotoPreview")
        XCTAssertNil(sut.lastTakenImage, "lastTakenImage")
    }
    
    func test_shouldPhotoTake_showPhotoPreviewShouldBeTrueAndLastTakenImageNotNil_afterShouldPhotoTakeSetToTrue() {
        let (sut, camManager) = makeSUT()
        
        let exp = XCTestExpectation(description: "should received showPhotoPreview")
        sut.$showPhotoPreview
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.shouldPhotoTake = true
        wait(for: [exp], timeout: 0.1)
        
        XCTAssertTrue(sut.shouldPhotoTake, "shouldPhotoTake")
        XCTAssertTrue(sut.showPhotoPreview, "showPhotoPreview")
        XCTAssertEqual(camManager.takePhotoCallCount, 1, "takePhotoCallCount")
        XCTAssertEqual(camManager.stopSessionCallCount, 1, "stopSessionCallCount")
        XCTAssertNotNil(sut.lastTakenImage, "lastTakenImage")
        XCTAssertEqual(sut.lastTakenImage, camManager.lastPhoto, "vm.lastTakenImage == camManager.lastPhoto")
    }
    
    func test_showPhotoPreview_startSessionShouldBeCalled_whenShowPhotoPreviewSetToFalse() {
        let (sut, camManager) = makeSUT()
        
        sut.showPhotoPreview = false
        
        XCTAssertFalse(sut.showPhotoPreview, "showPhotoPreview")
        XCTAssertEqual(camManager.startSessionCallCount, 1, "startSessionCallCount")
    }
    
    func test_videoRecordingStatus_videoRecordingStatusShouldBeNone_afterInitial() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.videoRecordingStatus, .none, "videoRecordingStatus")
        XCTAssertNil(sut.lastVideoUrl, "lastVideoUrl")
        XCTAssertFalse(sut.showVideoPreview, "showVideoPreview")
    }
    
    func test_videoRecordingStatus_videoRecordingStatusChanges() {
        let (sut, camManager) = makeSUT()
        
        let startVideoRecordingStatusExpectation = XCTestExpectation(description: "Should received VideoRecordingStatus.start")
        let stopVideoRecordingStatusExpectation = XCTestExpectation(description: "Should received VideoRecordingStatus.stop")
        let noneVideoRecordingStatusExpectation = XCTestExpectation(description: "Should received VideoRecordingStatus.none")
        sut.$videoRecordingStatus
            .dropFirst()
            .sink { status in
                switch status {
                case .none:
                    noneVideoRecordingStatusExpectation.fulfill()
                case .start:
                    startVideoRecordingStatusExpectation.fulfill()
                case .stop:
                    stopVideoRecordingStatusExpectation.fulfill()
                }
            }
            .store(in: &subscriptions)
        
        sut.videoRecordingStatus = .start
        
        wait(for: [startVideoRecordingStatusExpectation], timeout: 0.1)
        
        XCTAssertEqual(sut.videoRecordingStatus, .start, "videoRecordingStatus")
        XCTAssertNil(sut.lastVideoUrl, "lastVideoUrl")
        XCTAssertFalse(sut.showVideoPreview, "showVideoPreview")
        
        sut.videoRecordingStatus = .stop
        
        wait(for: [stopVideoRecordingStatusExpectation], timeout: 0.1)
        
        XCTAssertEqual(sut.videoRecordingStatus, .stop, "videoRecordingStatus")
        XCTAssertNil(sut.lastVideoUrl, "lastVideoUrl")
        XCTAssertFalse(sut.showVideoPreview, "showVideoPreview")
        
        camManager.finishVideoProcessing()
        
        wait(for: [noneVideoRecordingStatusExpectation], timeout: 0.1)
        
        XCTAssertEqual(sut.videoRecordingStatus, .none, "videoRecordingStatus")
        XCTAssertNotNil(sut.lastVideoUrl, "lastVideoUrl")
        XCTAssertTrue(sut.showVideoPreview, "showVideoPreview")
        XCTAssertEqual(sut.lastVideoUrl, camManager.lastVideoUrl, "vm.lastVideoUrl == camManager.lastVideoUrl")
        
        XCTAssertEqual(camManager.startVideoRecordingCallCount, 1, "startVideoRecordingCallCount")
        XCTAssertEqual(camManager.stopVideoRecordingCallCount, 1, "stopVideoRecordingCallCount")
    }
    
    func test_showVideoPreview_startSessionShouldBeCalled_whenShowVideoPreviewSetToFalse() {
        let (sut, camManager) = makeSUT()
        
        sut.showVideoPreview = false
        
        XCTAssertFalse(sut.showVideoPreview, "showVideoPreview")
        XCTAssertEqual(camManager.startSessionCallCount, 1, "startSessionCallCount")
    }
    
    func test_videoPreviewTapPoint_videoPreviewTapPointShouldBeZero_afterInitial() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.videoPreviewTapPoint, .zero)
    }
    
    func test_videoPreviewTapPoint_videoPreviewTapPointChanged_afterNewPointAssigned() {
        let (sut, camManager) = makeSUT()
        
        let point = CGPoint(x: CGFloat.random(in: 1...99), y: CGFloat.random(in: 1...99))
        sut.videoPreviewTapPoint = point
        
        XCTAssertEqual(sut.videoPreviewTapPoint, point, "videoPreviewTapPoint")
        XCTAssertEqual(sut.videoPreviewTapPoint, camManager.focusPoint, "vm.videoPreviewTapPoint == camManager.focusPoint")
    }
    
    func test_videoPreviewPinchFactor_videoPreviewPinchFactorShouldBeZero_afterInital() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.videoPreviewPinchFactor, .zero)
    }
    
    func test_videoPreviewPinchFactor_videoPreviewPinchFactorChanged_afterNewFactorAssigned() {
        let (sut, camManager) = makeSUT()
        
        let factor = CGFloat.random(in: 1...99)
        sut.videoPreviewPinchFactor = factor
        
        XCTAssertEqual(sut.videoPreviewPinchFactor, factor, "videoPreviewPinchFactor")
        XCTAssertEqual(sut.videoPreviewPinchFactor, camManager.zoomFactor, "vm.videoPreviewPinchFactor == camManager.zoomFactor")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(cameraAuthorizationTracker: DeviceAuthorizationTracker = DeviceAuthorizationTrackerStub(),
                         microphoneAuthorizationTracker: DeviceAuthorizationTracker = DeviceAuthorizationTrackerStub()) 
    -> (sut: StoryCamViewModel, camManager: MockCamManager) {
        let camManager = MockCamManager()
        let sut = StoryCamViewModel(
            camManager: camManager,
            cameraAuthorizationTracker: cameraAuthorizationTracker,
            microphoneAuthorizationTracker: microphoneAuthorizationTracker
        )
        return (sut, camManager)
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
