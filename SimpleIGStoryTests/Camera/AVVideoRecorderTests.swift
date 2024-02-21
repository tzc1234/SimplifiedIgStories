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
    
    // MARK: - Helpers
    
    private typealias VideoRecorderStatusSpy = StatusSpy<VideoRecorderStatus>
    
    private func makeSUT(isSessionRunning: Bool = false,
                         cameraPosition: CameraPosition = .back,
                         canAddMovieFileOutput: Bool = true,
                         captureMovieFileOutput: @escaping () -> AVCaptureMovieFileOutput = CaptureMovieFileOutputSpy.init,
                         outputPath: @escaping () -> URL = { URL(string: "file://any-video.mp4")! },
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
        let sut = AVVideoRecorder(
            device: device,
            captureMovieFileOutput: captureMovieFileOutput,
            outputPath: outputPath
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
    struct StartRecordingParam: Equatable {
        static func == (lhs: StartRecordingParam, rhs: StartRecordingParam) -> Bool {
            lhs.url == rhs.url && lhs.delegate === rhs.delegate
        }
        
        let url: URL
        weak var delegate: AVCaptureFileOutputRecordingDelegate?
    }
    
    private(set) var loggedConnection: CaptureConnectionStub?
    var preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode? {
        loggedConnection?.preferredVideoStabilizationMode
    }
    
    private(set) var startRecordingParams = [StartRecordingParam]()
    var startRecordingCallCount: Int {
        startRecordingParams.count
    }
    
    private(set) var stopRecordingCallCount = 0
    private(set) var loggedOutputSettings = [[String: Any]]()
    
    private var _isRecording = false
    override var isRecording: Bool {
        _isRecording
    }
    
    override var availableVideoCodecTypes: [AVVideoCodecType] {
        [.hevc]
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
    
    override func setOutputSettings(_ outputSettings: [String : Any]?, for connection: AVCaptureConnection) {
        outputSettings.map { loggedOutputSettings.append($0) }
        super.setOutputSettings(outputSettings, for: connection)
    }
    
    override func startRecording(to outputFileURL: URL, recordingDelegate delegate: AVCaptureFileOutputRecordingDelegate) {
        startRecordingParams.append(.init(url: outputFileURL, delegate: delegate))
        _isRecording = true
    }
    
    override func stopRecording() {
        stopRecordingCallCount += 1
        _isRecording = false
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
