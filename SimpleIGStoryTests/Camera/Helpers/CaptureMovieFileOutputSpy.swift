//
//  CaptureMovieFileOutputSpy.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 21/02/2024.
//

import AVFoundation

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
    
    override func setOutputSettings(_ outputSettings: [String: Any]?, for connection: AVCaptureConnection) {
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
