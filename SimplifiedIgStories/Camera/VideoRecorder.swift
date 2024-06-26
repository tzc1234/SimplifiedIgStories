//
//  VideoRecorder.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/02/2024.
//

import AVKit
import Combine

enum VideoRecorderStatus: Equatable {
    case recordingBegun
    case recordingFinished
    case videoProcessFailure
    case processedVideo(videoURL: URL)
    case addMovieFileOutputFailure
}

protocol VideoRecorder {
    func getStatusPublisher() -> AnyPublisher<VideoRecorderStatus, Never>
    func startRecording()
    func stopRecording()
}

final class AVVideoRecorder: NSObject, VideoRecorder {
    private let statusPublisher = PassthroughSubject<VideoRecorderStatus, Never>()
    private var backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
    
    private var session: AVCaptureSession {
        device.session
    }
    private var movieFileOutput: AVCaptureMovieFileOutput? {
        session.outputs.first(where: { $0 is AVCaptureMovieFileOutput }) as? AVCaptureMovieFileOutput
    }
    
    private let device: CaptureDevice
    private let captureMovieFileOutput: () -> AVCaptureMovieFileOutput
    private let outputPath: () -> URL
    private let beginBackgroundTask: () -> UIBackgroundTaskIdentifier
    private let endBackgroundTask: (UIBackgroundTaskIdentifier) -> Void
    
    init(device: CaptureDevice,
         captureMovieFileOutput: @escaping () -> AVCaptureMovieFileOutput = AVCaptureMovieFileOutput.init,
         outputPath: @escaping () -> URL = {
            FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
         },
         beginBackgroundTask: @escaping () -> UIBackgroundTaskIdentifier = { UIApplication.shared.beginBackgroundTask() },
         endBackgroundTask: @escaping (UIBackgroundTaskIdentifier) -> Void = UIApplication.shared.endBackgroundTask
    ) {
        self.device = device
        self.captureMovieFileOutput = captureMovieFileOutput
        self.outputPath = outputPath
        self.beginBackgroundTask = beginBackgroundTask
        self.endBackgroundTask = endBackgroundTask
        super.init()
        self.addMovieFileOutputIfNeeded()
    }
    
    func getStatusPublisher() -> AnyPublisher<VideoRecorderStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
    
    func startRecording() {
        device.performOnSessionQueue { [weak self] in
            guard let self else { return }
            
            guard let movieFileOutput, !movieFileOutput.isRecording else {
                return
            }
            
            backgroundRecordingID = beginBackgroundTask()
            
            setup(movieFileOutput)
            movieFileOutput.startRecording(to: outputPath(), recordingDelegate: self)
            statusPublisher.send(.recordingBegun)
        }
    }
    
    private func addMovieFileOutputIfNeeded() {
        guard movieFileOutput == nil else { return }
        
        session.beginConfiguration()
        
        let output = captureMovieFileOutput()
        guard session.canAddOutput(output) else {
            statusPublisher.send(.addMovieFileOutputFailure)
            return
        }
        
        session.addOutput(output)
        session.commitConfiguration()
    }
    
    private func setup(_ output: AVCaptureMovieFileOutput) {
        guard let connection = output.connection(with: .video) else {
            return
        }
        
        if output.availableVideoCodecTypes.contains(.hevc) {
            output.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
        }
        
        setup(connection: connection)
    }
    
    private func setup(connection: AVCaptureConnection) {
        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
        
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = device.cameraPosition == .front
        }
    }
    
    func stopRecording() {
        device.performOnSessionQueue { [weak self] in
            guard let self, let movieFileOutput, movieFileOutput.isRecording else {
                return
            }
            
            movieFileOutput.stopRecording()
            statusPublisher.send(.recordingFinished)
        }
    }
}

extension AVVideoRecorder: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        invalidateBackgroundRecordingTask()
        
        if error != nil {
            statusPublisher.send(.videoProcessFailure)
            return
        }
        
        statusPublisher.send(.processedVideo(videoURL: outputFileURL))
    }
    
    private func invalidateBackgroundRecordingTask() {
        if backgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
            endBackgroundTask(backgroundRecordingID)
            backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
        }
    }
}
