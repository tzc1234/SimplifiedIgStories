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
    private let makeCaptureMovieFileOutput: () -> AVCaptureMovieFileOutput
    
    init(device: VideoRecordDevice,
         makeCaptureMovieFileOutput: @escaping () -> AVCaptureMovieFileOutput = AVCaptureMovieFileOutput.init) {
        self.device = device
        self.makeCaptureMovieFileOutput = makeCaptureMovieFileOutput
    }
    
    func getStatusPublisher() -> AnyPublisher<VideoRecorderStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
    
    func startRecording() {
        device.performOnSessionQueue { [weak self] in
            guard let self else { return }
            
            addMovieFileOutputIfNeeded()
            
            guard let movieFileOutput else { return }
            
//            guard let self, let output = device.movieFileOutput, !output.isRecording else {
//                return
//            }
//            
//            backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
//            
            let cameraPosition = device.cameraPosition
            movieFileOutput.connection(with: .video).map { connection in
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = cameraPosition == .front
                }
            }
            
//
//            if output.availableVideoCodecTypes.contains(.hevc) {
//                output.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: outputConnection)
//            }
//            
//            output.startRecording(to: getOutputPath(), recordingDelegate: self)
//            
//            statusPublisher.send(.recordingBegun)
        }
    }
    
    private func addMovieFileOutputIfNeeded() {
        guard movieFileOutput == nil else {
            return
        }
        
        session.beginConfiguration()
        
        let output = makeCaptureMovieFileOutput()
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
    
    private func getOutputPath() -> URL {
        let fileName = UUID().uuidString
        return FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
            .appendingPathExtension("mov")
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

