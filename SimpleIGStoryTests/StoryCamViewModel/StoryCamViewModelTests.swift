//
//  StoryCamViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 16/07/2022.
//

import XCTest
import Combine
@testable import Simple_IG_Story

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
    
    @MainActor
    func test_checkPermissions_permissionsAreNotGranted_beforeFunctionCalled() {
        let (sut, _) = makeSUT()
        
        XCTAssertFalse(sut.isCamPermGranted, "camera permission")
        XCTAssertFalse(sut.isMicrophonePermGranted, "microphone permission")
        XCTAssertFalse(sut.arePermissionsGranted, "both permissions")
    }
    
    @MainActor
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
    
    @MainActor
    func test_videoPreviewLayer_returnTheSameLayerAsCamManagerVideoPreviewLayer() {
        let (sut, camera) = makeSUT()
        
        XCTAssertIdentical(sut.videoPreviewLayer, camera.videoPreviewLayer)
    }

    @MainActor
    func test_setupAndStartSession_enableVideoRecordBtnShouldBeFalse_beforeFunctionCalled() {
        let (sut, camera) = makeSUT()
        
        XCTAssertFalse(sut.enableVideoRecordBtn, "enableVideoRecordBtn")
        XCTAssertEqual(camera.startSessionCallCount, 0, "setupAndStartSessionCallCount")
    }
    
    @MainActor
    func test_setupAndStartSession_enableVideoRecordBtnShouldBeTrueAndSessionShouldBeStarted_afterFunctionCalled() {
        let (sut, camera) = makeSUT()
        
        let camStatusPublisherExpectation = XCTestExpectation(description: "should receive status from camStatusPublisher")
        let enableVideoRecordBtnExpectation = XCTestExpectation(description: "should receive enableVideoRecordBtn value")
        camera.getStatusPublisher()
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
        
        sut.startSession()
        wait(for: [camStatusPublisherExpectation, enableVideoRecordBtnExpectation], timeout: 0.1)
        
        XCTAssertTrue(sut.enableVideoRecordBtn, "enableVideoRecordBtn")
        XCTAssertEqual(camera.startSessionCallCount, 1, "setupAndStartSessionCallCount")
    }
    
    @MainActor
    func test_switchCamera_camPositionShouldBeBack_beforeFunctionCalled() {
        let (_, camera) = makeSUT()
        
        XCTAssertEqual(camera.switchCameraCallCount, 0, "switchCameraCallCount")
        XCTAssertEqual(camera.cameraPosition, .back, "camPosition")
    }
    
    @MainActor
    func test_switchCamera_shouldReceiveCameraSwitchedStatus_afterFunctionCalled() {
        let (sut, camera) = makeSUT()
        
        camera.getStatusPublisher()
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
        
        XCTAssertEqual(camera.switchCameraCallCount, 1, "switchCameraCallCount")
        XCTAssertEqual(camera.cameraPosition, .front, "camPosition")
    }
    
    @MainActor
    func test_shouldPhotoTake_shouldPhotoTakeShouldBeFalse_afterInitial() {
        let (sut, _) = makeSUT()
        
        XCTAssertFalse(sut.shouldPhotoTake, "shouldPhotoTake")
        XCTAssertFalse(sut.showPhotoPreview, "showPhotoPreview")
        XCTAssertNil(sut.lastTakenImage, "lastTakenImage")
    }
    
    @MainActor
    func test_shouldPhotoTake_showPhotoPreviewShouldBeTrueAndLastTakenImageNotNil_afterShouldPhotoTakeSetToTrue() {
        let photoTaker = PhotoTakerSpy()
        let (sut, camera) = makeSUT(photoTaker: photoTaker)
        
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
        XCTAssertEqual(photoTaker.takePhotoCallCount, 1, "takePhotoCallCount")
        XCTAssertEqual(camera.stopSessionCallCount, 1, "stopSessionCallCount")
        XCTAssertNotNil(sut.lastTakenImage, "lastTakenImage")
        XCTAssertEqual(sut.lastTakenImage, photoTaker.lastPhoto, "vm.lastTakenImage == camera.lastPhoto")
    }
    
    @MainActor
    func test_showPhotoPreview_startSessionShouldBeCalled_whenShowPhotoPreviewSetToFalse() {
        let (sut, camera) = makeSUT()
        
        sut.showPhotoPreview = false
        
        XCTAssertFalse(sut.showPhotoPreview, "showPhotoPreview")
        XCTAssertEqual(camera.startSessionCallCount, 1, "startSessionCallCount")
    }
    
    @MainActor
    func test_videoRecordingStatus_videoRecordingStatusShouldBeNone_afterInitial() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.videoRecordingStatus, .none, "videoRecordingStatus")
        XCTAssertNil(sut.lastVideoUrl, "lastVideoUrl")
        XCTAssertFalse(sut.showVideoPreview, "showVideoPreview")
    }
    
    @MainActor
    func test_videoRecordingStatus_videoRecordingStatusChanges() {
        let videoRecorder = VideoRecorderSpy()
        let (sut, _) = makeSUT(videoRecorder: videoRecorder)
        
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
        
        videoRecorder.finishVideoProcessing()
        
        wait(for: [noneVideoRecordingStatusExpectation], timeout: 0.1)
        
        XCTAssertEqual(sut.videoRecordingStatus, .none, "videoRecordingStatus")
        XCTAssertNotNil(sut.lastVideoUrl, "lastVideoUrl")
        XCTAssertTrue(sut.showVideoPreview, "showVideoPreview")
        XCTAssertEqual(sut.lastVideoUrl, videoRecorder.lastVideoUrl, "vm.lastVideoUrl == camera.lastVideoUrl")
        
        XCTAssertEqual(videoRecorder.startVideoRecordingCallCount, 1, "startVideoRecordingCallCount")
        XCTAssertEqual(videoRecorder.stopVideoRecordingCallCount, 1, "stopVideoRecordingCallCount")
    }
    
    @MainActor
    func test_showVideoPreview_startSessionShouldBeCalled_whenShowVideoPreviewSetToFalse() {
        let (sut, camera) = makeSUT()
        
        sut.showVideoPreview = false
        
        XCTAssertFalse(sut.showVideoPreview, "showVideoPreview")
        XCTAssertEqual(camera.startSessionCallCount, 1, "startSessionCallCount")
    }
    
    @MainActor
    func test_videoPreviewTapPoint_videoPreviewTapPointShouldBeZero_afterInitial() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.videoPreviewTapPoint, .zero)
    }
    
    @MainActor
    func test_videoPreviewTapPoint_videoPreviewTapPointChanged_afterNewPointAssigned() {
        let cameraAuxiliary = CameraAuxiliarySpy()
        let (sut, _) = makeSUT(cameraAuxiliary: cameraAuxiliary)
        
        let point = CGPoint(x: CGFloat.random(in: 1...99), y: CGFloat.random(in: 1...99))
        sut.videoPreviewTapPoint = point
        
        XCTAssertEqual(sut.videoPreviewTapPoint, point, "videoPreviewTapPoint")
        XCTAssertEqual(sut.videoPreviewTapPoint, cameraAuxiliary.focusPoint, "vm.videoPreviewTapPoint == camera.focusPoint")
    }
    
    @MainActor
    func test_videoPreviewPinchFactor_videoPreviewPinchFactorShouldBeZero_afterInital() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.videoPreviewPinchFactor, .zero)
    }
    
    @MainActor
    func test_videoPreviewPinchFactor_videoPreviewPinchFactorChanged_afterNewFactorAssigned() {
        let cameraAuxiliary = CameraAuxiliarySpy()
        let (sut, _) = makeSUT(cameraAuxiliary: cameraAuxiliary)
        
        let factor = CGFloat.random(in: 1...99)
        sut.videoPreviewPinchFactor = factor
        
        XCTAssertEqual(sut.videoPreviewPinchFactor, factor, "videoPreviewPinchFactor")
        XCTAssertEqual(sut.videoPreviewPinchFactor, cameraAuxiliary.zoomFactor, "vm.videoPreviewPinchFactor == camera.zoomFactor")
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeSUT(photoTaker: PhotoTakerSpy = PhotoTakerSpy(),
                         videoRecorder: VideoRecorderSpy = VideoRecorderSpy(),
                         cameraAuxiliary: CameraAuxiliarySpy = CameraAuxiliarySpy(),
                         cameraAuthorizationTracker: DeviceAuthorizationTracker = DeviceAuthorizationTrackerStub(),
                         microphoneAuthorizationTracker: DeviceAuthorizationTracker = DeviceAuthorizationTrackerStub())
    -> (sut: StoryCamViewModel, camera: CameraSpy) {
        let camera = CameraSpy()
        let sut = StoryCamViewModel(
            camera: camera,
            photoTaker: photoTaker,
            videoRecorder: videoRecorder,
            cameraAuxiliary: cameraAuxiliary,
            cameraAuthorizationTracker: cameraAuthorizationTracker,
            microphoneAuthorizationTracker: microphoneAuthorizationTracker
        )
        return (sut, camera)
    }
    
    private class PhotoTakerSpy: PhotoTaker {
        private(set) var takePhotoCallCount = 0
        private(set) var lastPhoto: UIImage?
        
        private let publisher = PassthroughSubject<PhotoTakerStatus, Never>()
        
        func getStatusPublisher() -> AnyPublisher<PhotoTakerStatus, Never> {
            publisher.eraseToAnyPublisher()
        }
        
        func takePhoto(on mode: CameraFlashMode) {
            takePhotoCallCount += 1
            let lastPhoto = UIImage()
            self.lastPhoto = lastPhoto
            publisher.send(.photoTaken(photo: lastPhoto))
        }
    }
    
    private class VideoRecorderSpy: VideoRecorder {
        private(set) var startVideoRecordingCallCount = 0
        private(set) var stopVideoRecordingCallCount = 0
        private(set) var lastVideoUrl: URL?
        
        private let publisher = PassthroughSubject<VideoRecorderStatus, Never>()
        
        func getStatusPublisher() -> AnyPublisher<VideoRecorderStatus, Never> {
            publisher.eraseToAnyPublisher()
        }
        
        func startRecording() {
            startVideoRecordingCallCount += 1
            publisher.send(.recordingBegun)
        }
        
        func stopRecording() {
            stopVideoRecordingCallCount += 1
            publisher.send(.recordingFinished)
        }
        
        func finishVideoProcessing() {
            let lastVideoUrl = URL(string: "videoURL")!
            self.lastVideoUrl = lastVideoUrl
            publisher.send(.processedVideo(videoURL: lastVideoUrl))
        }
    }
    
    private class CameraAuxiliarySpy: CameraAuxiliary {
        private(set) var focusPoint: CGPoint?
        private(set) var zoomFactor: CGFloat?
        
        func focus(on point: CGPoint) {
            focusPoint = point
        }
        
        func zoom(to factor: CGFloat) {
            zoomFactor = factor
        }
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
