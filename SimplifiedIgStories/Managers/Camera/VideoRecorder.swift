//
//  VideoRecorder.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/02/2024.
//

import AVKit
import Combine

enum VideoRecorderStatus {
    case recordingBegun
    case recordingFinished
    case videoProcessFailure
    case processedVideo(videoURL: URL)
}

protocol VideoRecorder {
    func getStatusPublisher() -> AnyPublisher<VideoRecorderStatus, Never>
    func startRecording()
    func stopRecording()
}

protocol VideoRecordDevice {
    var cameraPosition: CameraPosition { get }
    var movieFileOutput: AVCaptureMovieFileOutput? { get }
    func performOnSessionQueue(action: @escaping () -> Void)
}

final class AVCaptureVideoRecorder: NSObject, VideoRecorder {
    private let statusPublisher = PassthroughSubject<VideoRecorderStatus, Never>()
    private var backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
    
    private let device: VideoRecordDevice
    
    init(device: VideoRecordDevice) {
        self.device = device
    }
    
    func getStatusPublisher() -> AnyPublisher<VideoRecorderStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
    
    func startRecording() {
        device.performOnSessionQueue { [weak self] in
            guard let self, let output = device.movieFileOutput, !output.isRecording else {
                return
            }
            
            backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            
            guard let outputConnection = output.connection(with: .video) else {
                return
            }
            
            outputConnection.videoOrientation = .portrait
            outputConnection.isVideoMirrored = device.cameraPosition == .front
            
            if output.availableVideoCodecTypes.contains(.hevc) {
                output.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: outputConnection)
            }
            
            output.startRecording(to: getOutputPath(), recordingDelegate: self)
            
            statusPublisher.send(.recordingBegun)
        }
    }
    
    private func getOutputPath() -> URL {
        let fileName = UUID().uuidString
        return FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
            .appendingPathExtension("mov")
    }
    
    func stopRecording() {
        device.performOnSessionQueue { [weak self] in
            guard let self, let output = device.movieFileOutput, output.isRecording else {
                return
            }
            
            output.stopRecording()
            statusPublisher.send(.recordingFinished)
        }
    }
}

extension AVCaptureVideoRecorder: AVCaptureFileOutputRecordingDelegate {
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

