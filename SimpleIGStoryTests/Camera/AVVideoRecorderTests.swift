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
        let movieFileOutputSpy = CaptureMovieFileOutputSpy()
        let (sut, device) = makeSUT(isSessionRunning: false, captureMovieFileOutput: { movieFileOutputSpy })
        
        sut.startRecording()
        
        XCTAssertEqual(device.loggedMovieFileOutputs.count, 1)
        XCTAssertEqual(movieFileOutputSpy.preferredVideoStabilizationMode, .auto)
    }
    
    // MARK: - Helpers
    
    private typealias VideoRecorderStatusSpy = StatusSpy<VideoRecorderStatus>
    
    private func makeSUT(isSessionRunning: Bool = false,
                         captureMovieFileOutput: @escaping () -> AVCaptureMovieFileOutput = AVCaptureMovieFileOutput.init,
                         perform: @escaping (@escaping () -> Void) -> Void = { $0() }, 
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: AVVideoRecorder, device: VideoRecordDeviceSpy) {
        let device = VideoRecordDeviceSpy(
            isSessionRunning: isSessionRunning,
            performOnSessionQueue: perform
        )
        let sut = AVVideoRecorder(device: device, makeCaptureMovieFileOutput: captureMovieFileOutput)
        trackForMemoryLeaks(device, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, device)
    }
    
    private final class VideoRecordDeviceSpy: VideoRecordDevice {
        private(set) var cameraPosition = CameraPosition.back
        let session: AVCaptureSession
        var loggedMovieFileOutputs: [AVCaptureMovieFileOutput] {
            (session as! CaptureSessionSpy).loggedMovieFileOutputs
        }
        
        let performOnSessionQueue: (@escaping () -> Void) -> Void
        
        init(isSessionRunning: Bool,
             performOnSessionQueue: @escaping (@escaping () -> Void) -> Void) {
            let session = CaptureSessionSpy(isRunning: isSessionRunning, canAddOutput: true)
            self.session = session
            self.performOnSessionQueue = performOnSessionQueue
        }
    }
}

final class CaptureMovieFileOutputSpy: AVCaptureMovieFileOutput {
    private var connection: CaptureConnectionStub?
    var preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode? {
        connection?.preferredVideoStabilizationMode
    }
    
    override func connection(with mediaType: AVMediaType) -> AVCaptureConnection? {
        connection = CaptureConnectionStub(inputPorts: [], output: self)
        return connection
    }
}

final class CaptureConnectionStub: AVCaptureConnection {
    private var stabilizationMode = AVCaptureVideoStabilizationMode.off
    
    override var isVideoStabilizationSupported: Bool {
        true
    }
    
    override var preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode {
        get { stabilizationMode }
        set { stabilizationMode = newValue }
    }
}
