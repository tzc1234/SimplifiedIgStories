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

protocol VideoRecordDevice {
    var cameraPosition: CameraPosition { get }
    var session: AVCaptureSession { get }
    var performOnSessionQueue: (@escaping () -> Void) -> Void { get }
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
    
    private let device: VideoRecordDevice
    private let captureMovieFileOutput: () -> AVCaptureMovieFileOutput
    private let outputPath: () -> URL
    
    init(device: VideoRecordDevice,
         captureMovieFileOutput: @escaping () -> AVCaptureMovieFileOutput = AVCaptureMovieFileOutput.init,
         outputPath: @escaping () -> URL = {
            FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
        }
    ) {
        self.device = device
        self.captureMovieFileOutput = captureMovieFileOutput
        self.outputPath = outputPath
    }
    
    func getStatusPublisher() -> AnyPublisher<VideoRecorderStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
    
    func startRecording() {
        device.performOnSessionQueue { [weak self] in
            guard let self else { return }
            
            addMovieFileOutputIfNeeded()
            
            guard let movieFileOutput,
                  let connection = movieFileOutput.connection(with: .video),
                  !movieFileOutput.isRecording else {
                return
            }
            
//            backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = device.cameraPosition == .front
            }
            
            if movieFileOutput.availableVideoCodecTypes.contains(.hevc) {
                movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
            }
            
            movieFileOutput.startRecording(to: outputPath(), recordingDelegate: self)
            statusPublisher.send(.recordingBegun)
        }
    }
    
    private func addMovieFileOutputIfNeeded() {
        guard movieFileOutput == nil else {
            return
        }
        
        session.beginConfiguration()
        
        let output = captureMovieFileOutput()
        guard session.canAddOutput(output) else {
            statusPublisher.send(.addMovieFileOutputFailure)
            return
        }
        
        session.addOutput(output)
        setAutoVideoStabilizationMode(on: output)
        
        session.commitConfiguration()
    }
    
    private func setAutoVideoStabilizationMode(on output: AVCaptureMovieFileOutput) {
        if let connection = output.connection(with: .video), connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
    }
    
    func stopRecording() {
//        device.performOnSessionQueue { [weak self] in
//            guard let self, let output = device.movieFileOutput, output.isRecording else {
//                return
//            }
//            
//            output.stopRecording()
//            statusPublisher.send(.recordingFinished)
//        }
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
            UIApplication.shared.endBackgroundTask(backgroundRecordingID)
            backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
        }
    }
}

