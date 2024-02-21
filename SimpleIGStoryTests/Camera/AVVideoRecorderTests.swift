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
        let (sut, _) = makeSUT()
        let statusSpy = VideoRecorderStatusSpy(publisher: sut.getStatusPublisher())
        
        XCTAssertTrue(statusSpy.loggedStatuses.isEmpty)
    }
    
    func test_startRecording_addsMovieFileOutputIfNoMovieFileOutputWhenSessionIsNotRunning() {
        let (sut, device) = makeSUT(isSessionRunning: false)
        
        sut.startRecording()
        
        assertMovieFileOutput(on: device)
    }
    
    func test_startRecording_addsMovieFileOutputIfNoMovieFileOutputWhenSessionIsRunning() {
        let (sut, device) = makeSUT(isSessionRunning: true)
        
        sut.startRecording()
        
        assertMovieFileOutput(on: device)
    }
    
    func test_startRecording_doesNotAddMovieFileOutputAgainIfItIsAlreadyAdded() {
        let (sut, device) = makeSUT()
        
        sut.startRecording()
        sut.startRecording()
        
        assertMovieFileOutput(on: device)
    }
    
    func test_startRecording_deliversAddMovieFileOutputFailureStatusWhenCannotAddMovieFileOutput() {
        let (sut, _) = makeSUT(canAddMovieFileOutput: false)
        let statusSpy = VideoRecorderStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.startRecording()
        
        XCTAssertEqual(statusSpy.loggedStatuses, [.addMovieFileOutputFailure])
    }
    
    func test_startRecording_doesNotStartRecordingWhenItIsAlreadyRecording() {
        let movieFileOutput = CaptureMovieFileOutputSpy()
        movieFileOutput.setRecording(true)
        let (sut, _) = makeSUT(captureMovieFileOutput: { movieFileOutput })
        
        sut.startRecording()
        
        XCTAssertEqual(movieFileOutput.startRecordingCallCount, 0)
    }
    
    func test_startRecording_setupCaptureConnectionCorrectlyWithBackCamera() throws {
        let (sut, device) = makeSUT(cameraPosition: .back)
        
        sut.startRecording()
        
        let captureConnection = try XCTUnwrap(device.movieFileOutput?.loggedConnection)
        XCTAssertEqual(captureConnection.videoOrientation, .portrait)
        XCTAssertFalse(captureConnection.isVideoMirrored)
    }
    
    func test_startRecording_setupCaptureConnectionCorrectlyWithFrontCamera() throws {
        let (sut, device) = makeSUT(cameraPosition: .front)
        
        sut.startRecording()
        
        let captureConnection = try XCTUnwrap(device.movieFileOutput?.loggedConnection)
        XCTAssertEqual(captureConnection.videoOrientation, .portrait)
        XCTAssertTrue(captureConnection.isVideoMirrored)
    }
    
    func test_startRecording_setsOutputSettingsCorrectly() throws {
        let (sut, device) = makeSUT()
        
        sut.startRecording()
        
        let movieFileOutput = try XCTUnwrap(device.movieFileOutput)
        XCTAssertEqual(movieFileOutput.loggedOutputSettings.count, 1)
        XCTAssertEqual(
            movieFileOutput.loggedOutputSettings.last as? [String: AVVideoCodecType],
            [AVVideoCodecKey: .hevc]
        )
    }
    
    func test_startRecording_startsWhenItIsNotRecording() {
        let movieFileOutput = CaptureMovieFileOutputSpy()
        movieFileOutput.setRecording(false)
        let filePath = URL(string: "file://test-video.mp4")!
        let (sut, _) = makeSUT(captureMovieFileOutput: { movieFileOutput }, outputPath: { filePath })
        let statusSpy = VideoRecorderStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.startRecording()
        
        XCTAssertEqual(movieFileOutput.startRecordingParams, [.init(url: filePath, delegate: sut)])
        XCTAssertEqual(statusSpy.loggedStatuses, [.recordingBegun])
    }
    
    func test_stopRecording_stopsRecordingWhenItIsRecording() {
        let (sut, device) = makeSUT()
        let statusSpy = VideoRecorderStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.startRecording()
        
        XCTAssertEqual(device.movieFileOutput?.stopRecordingCallCount, 0)
        XCTAssertEqual(statusSpy.loggedStatuses, [.recordingBegun])
        
        sut.stopRecording()
        
        XCTAssertEqual(device.movieFileOutput?.stopRecordingCallCount, 1)
        XCTAssertEqual(statusSpy.loggedStatuses, [.recordingBegun, .recordingFinished])
    }
    
    func test_performOnSessionQueue_performsBothStartAndStopRecordingOnSessionQueue() {
        var loggedActions = [() -> Void]()
        let (sut, device) = makeSUT(perform: { loggedActions.append($0) })
        
        sut.startRecording()
        sut.stopRecording()
        
        XCTAssertNil(device.movieFileOutput)
        
        loggedActions.forEach { $0() }
        
        XCTAssertEqual(device.movieFileOutput?.startRecordingCallCount, 1)
        XCTAssertEqual(device.movieFileOutput?.stopRecordingCallCount, 1)
    }
    
    func test_backgroundRecordingID_assignsBackgroundRecordingIDAfterStartRecording() {
        let recordingID = UIBackgroundTaskIdentifier(rawValue: 999)
        let (sut, _) = makeSUT(beginBackgroundTask: { recordingID })
        
        XCTAssertEqual(sut.backgroundRecordingID, .invalid)
        
        sut.startRecording()
        
        XCTAssertEqual(sut.backgroundRecordingID, recordingID)
    }
    
    func test_backgroundRecordingID_invalidatesBackgroundRecordingIDAfterFileOutput() {
        let recordingID = UIBackgroundTaskIdentifier(rawValue: 999)
        var loggedBackgroundRecordingIDs = [UIBackgroundTaskIdentifier]()
        let (sut, _) = makeSUT(
            beginBackgroundTask: { recordingID },
            endBackgroundTask: { loggedBackgroundRecordingIDs.append($0) }
        )
        
        sut.startRecording()
        sut.fileOutput(anyCaptureFileOutput(), didFinishRecordingTo: anyVideoURL(), from: [], error: nil)
        
        XCTAssertEqual(loggedBackgroundRecordingIDs, [recordingID])
        XCTAssertEqual(sut.backgroundRecordingID, .invalid)
    }
    
    func test_fileOutput_deliversVideoProcessFailureStatusOnFileOutputError() {
        let (sut, _) = makeSUT()
        let statusSpy = VideoRecorderStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.fileOutput(anyCaptureFileOutput(), didFinishRecordingTo: anyVideoURL(), from: [], error: anyNSError())
        
        XCTAssertEqual(statusSpy.loggedStatuses, [.videoProcessFailure])
    }
    
    func test_fileOutput_deliversVideoURLWhenFileOutputSucceeded() {
        let (sut, _) = makeSUT()
        let videoURL = URL(string: "file://test-video.mp4")!
        let statusSpy = VideoRecorderStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.fileOutput(anyCaptureFileOutput(), didFinishRecordingTo: videoURL, from: [], error: nil)
        
        XCTAssertEqual(statusSpy.loggedStatuses, [.processedVideo(videoURL: videoURL)])
    }
    
    // MARK: - Helpers
    
    private typealias VideoRecorderStatusSpy = StatusSpy<VideoRecorderStatus>
    
    private func makeSUT(isSessionRunning: Bool = false,
                         cameraPosition: CameraPosition = .back,
                         canAddMovieFileOutput: Bool = true,
                         captureMovieFileOutput: @escaping () -> AVCaptureMovieFileOutput 
                            = CaptureMovieFileOutputSpy.init,
                         outputPath: @escaping () -> URL = { anyVideoURL() },
                         perform: @escaping (@escaping () -> Void) -> Void = { $0() },
                         beginBackgroundTask: @escaping () -> UIBackgroundTaskIdentifier 
                            = { UIBackgroundTaskIdentifier.invalid },
                         endBackgroundTask: @escaping (UIBackgroundTaskIdentifier) -> Void = { _ in },
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: AVVideoRecorder, device: VideoRecordDeviceSpy) {
        CaptureSessionSpy.swizzled()
        let device = VideoRecordDeviceSpy(
            isSessionRunning: isSessionRunning,
            cameraPosition: cameraPosition,
            canAddMovieFileOutput: canAddMovieFileOutput,
            performOnSessionQueue: perform
        )
        let sut = AVVideoRecorder(
            device: device,
            captureMovieFileOutput: captureMovieFileOutput,
            outputPath: outputPath,
            beginBackgroundTask: beginBackgroundTask,
            endBackgroundTask: endBackgroundTask
        )
        addTeardownBlock {
            CaptureSessionSpy.revertSwizzled()
        }
        trackForMemoryLeaks(device, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, device)
    }
    
    private func assertMovieFileOutput(on device: VideoRecordDeviceSpy, 
                                       file: StaticString = #filePath,
                                       line: UInt = #line) {
        XCTAssertEqual(device.loggedMovieFileOutputs.count, 1, file: file, line: line)
        XCTAssertEqual(device.movieFileOutput?.preferredVideoStabilizationMode, .auto, file: file, line: line)
    }
    
    private func anyCaptureFileOutput() -> AVCaptureFileOutput {
        AVCaptureMovieFileOutput()
    }
    
    private final class VideoRecordDeviceSpy: VideoRecordDevice {
        var loggedMovieFileOutputs: [AVCaptureMovieFileOutput] {
            (session as! CaptureSessionSpy).loggedMovieFileOutputs
        }
        var movieFileOutput: CaptureMovieFileOutputSpy? {
            loggedMovieFileOutputs.last as? CaptureMovieFileOutputSpy
        }
        
        let session: AVCaptureSession
        let cameraPosition: CameraPosition
        let performOnSessionQueue: (@escaping () -> Void) -> Void
        
        init(isSessionRunning: Bool,
             cameraPosition: CameraPosition,
             canAddMovieFileOutput: Bool,
             performOnSessionQueue: @escaping (@escaping () -> Void) -> Void) {
            let session = CaptureSessionSpy(isRunning: isSessionRunning, canAddOutput: canAddMovieFileOutput)
            self.session = session
            self.cameraPosition = cameraPosition
            self.performOnSessionQueue = performOnSessionQueue
        }
    }
}
