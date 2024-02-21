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
    
    // MARK: - Helpers
    
    private typealias VideoRecorderStatusSpy = StatusSpy<VideoRecorderStatus>
    
    private func makeSUT(isSessionRunning: Bool = false,
                         cameraPosition: CameraPosition = .back,
                         canAddMovieFileOutput: Bool = true,
                         captureMovieFileOutput: @escaping () -> AVCaptureMovieFileOutput = CaptureMovieFileOutputSpy.init,
                         perform: @escaping (@escaping () -> Void) -> Void = { $0() },
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: AVVideoRecorder, device: VideoRecordDeviceSpy) {
        CaptureSessionSpy.swizzled()
        let device = VideoRecordDeviceSpy(
            isSessionRunning: isSessionRunning,
            cameraPosition: cameraPosition,
            canAddMovieFileOutput: canAddMovieFileOutput,
            performOnSessionQueue: perform
        )
        let sut = AVVideoRecorder(device: device, makeCaptureMovieFileOutput: captureMovieFileOutput)
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

final class CaptureMovieFileOutputSpy: AVCaptureMovieFileOutput {
    private(set) var loggedConnection: CaptureConnectionStub?
    var preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode? {
        loggedConnection?.preferredVideoStabilizationMode
    }
    
    private(set) var startRecordingCallCount = 0
    
    private var _isRecording = false
    override var isRecording: Bool {
        _isRecording
    }
    
    func setRecording(_ bool: Bool) {
        _isRecording = bool
    }
    
    override func connection(with mediaType: AVMediaType) -> AVCaptureConnection? {
        guard mediaType == .video else { return nil }
        
        if let loggedConnection {
            return loggedConnection
        }
        
        loggedConnection = CaptureConnectionStub(inputPorts: [], output: self)
        return loggedConnection
    }
    
    override func startRecording(to outputFileURL: URL, recordingDelegate delegate: AVCaptureFileOutputRecordingDelegate) {
        startRecordingCallCount += 1
    }
}

final class CaptureConnectionStub: AVCaptureConnection {
    private var stabilizationMode = AVCaptureVideoStabilizationMode.off
    private var _videoOrientation =  AVCaptureVideoOrientation.portraitUpsideDown
    private var _isVideoMirrored = false
    
    override var isVideoStabilizationSupported: Bool {
        true
    }
    
    override var isVideoOrientationSupported: Bool {
        true
    }
    
    override var isVideoMirroringSupported: Bool {
        true
    }
    
    override var preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode {
        get { stabilizationMode }
        set { stabilizationMode = newValue }
    }
    
    override var videoOrientation: AVCaptureVideoOrientation {
        get { _videoOrientation }
        set { _videoOrientation = newValue }
    }
    
    override var isVideoMirrored: Bool {
        get { _isVideoMirrored }
        set { _isVideoMirrored = newValue }
    }
}
