//
//  CamManager.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/06/2022.
//

import AVFoundation
import Combine
import UIKit

enum CamSetupError: Error {
    case defaultVideoDeviceUnavailable
    case createVideoDeviceInputFailure(err: Error)
    case addVideoDeviceInputFailure
    case defaultAudioDeviceUnavailable
    case createAudioDeviceInputFailure(err: Error)
    case addAudioDeviceInputFailure
    case addMovieFileOutputFailure
    case addPhotoOutputFailure
    case backgroundAudioPreferenceSetupFailure
    
    var errMsg: String {
        switch self {
        case .defaultVideoDeviceUnavailable:
            return "Default video device is unavailable."
        case .createVideoDeviceInputFailure(let err):
            return "Cannot create video device input: \(err)"
        case .addVideoDeviceInputFailure:
            return "Cannot add video device input to the session."
        case .defaultAudioDeviceUnavailable:
            return "Default audio device is unavailable."
        case .createAudioDeviceInputFailure(let err):
            return "Cannot create audio device input: \(err)"
        case .addAudioDeviceInputFailure:
            return "Cannot add audio device input to the session."
        case .addMovieFileOutputFailure:
            return "Cannot add movie file output to the session."
        case .addPhotoOutputFailure:
            return "Cannot add photo output to the session."
        case .backgroundAudioPreferenceSetupFailure:
            return "Cannot set background audio preference."
        }
    }
}

protocol CamManager {
    
}

// MARK: - CamStatus For Publishing
enum CamStatus {
    case sessionStarted
    case sessionStopped
    case photoTaken(photo: UIImage)
    case recordingVideoBegun
    case recordingVideoFinished
    case processingVideoFinished(videoUrl: URL)
    case cameraSwitched(camPosition: AVCaptureDevice.Position)
    case focused(atPoint: CGPoint)
    case zoomLevelChanged(zoomLevel: CGFloat)
    case notAuthorized
    case configureFailure
    case recordingVideoFailure(err: Error)
}

// MARK: - AVCamManager
final class AVCamManager: NSObject, CamManager {
    @Published private(set) var camPermGranted = false
    @Published private(set) var microphonePermGranted = false
    let publisher = PassthroughSubject<CamStatus, Never>()
    
    private let sessionQueue = DispatchQueue(label: "AVCamSessionQueue")
    
    let session = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput?
    var movieFileOutput: AVCaptureMovieFileOutput?
    var photoOutput: AVCapturePhotoOutput?
    var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    var camPosition: AVCaptureDevice.Position = .back
    var flashMode: AVCaptureDevice.FlashMode = .off
    
    private var subscriptions = Set<AnyCancellable>()
}

// MARK: - private functions
extension AVCamManager {
    private func addVideoInput() throws {
        guard let videoDevice =
                AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: camPosition)
        else {
            throw CamSetupError.defaultVideoDeviceUnavailable
        }

        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                throw CamSetupError.addVideoDeviceInputFailure
            }
        } catch {
            throw CamSetupError.createVideoDeviceInputFailure(err: error)
        }
    }
    
    private func addAudioInput() throws {
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            throw CamSetupError.defaultAudioDeviceUnavailable
        }
        
        do {
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                throw CamSetupError.addAudioDeviceInputFailure
            }
        } catch {
            throw CamSetupError.createAudioDeviceInputFailure(err: error)
        }
    }
    
    private func addVideoOutput() throws {
        let movieFileOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(movieFileOutput) {
            session.addOutput(movieFileOutput)
            
            if let connection = movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            
            self.movieFileOutput = movieFileOutput
        } else {
            throw CamSetupError.addMovieFileOutputFailure
        }
    }
    
    private func addPhotoOutput() throws {
        let photoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            self.photoOutput = photoOutput
        } else {
            throw CamSetupError.addPhotoOutputFailure
        }
    }
    
    private func setBackgroundAudioPreference() throws {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            throw CamSetupError.backgroundAudioPreferenceSetupFailure
        }
    }
}

// MARK: - internal functions
extension AVCamManager {
    func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            do {
                try self.addVideoInput()
                try self.addAudioInput()
                try self.addVideoOutput()
                try self.addPhotoOutput()
            } catch {
                let errMsg = (error as? CamSetupError)?.errMsg ?? error.localizedDescription
                print(errMsg)
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.camPosition = self.camPosition == .back ? .front : .back
            
            // Remove all inputs first.
            for input in self.session.inputs {
                self.session.removeInput(input)
            }

            // Re-add inputs.
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            do {
                try self.addVideoInput()
                try self.addAudioInput()
            } catch {
                let errMsg = (error as? CamSetupError)?.errMsg ?? error.localizedDescription
                print(errMsg)
            }
            
            self.session.commitConfiguration()
            self.publisher.send(.cameraSwitched(camPosition: self.camPosition))
        }
    }
    
    func takePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self, let photoOutput = self.photoOutput else {
                return
            }
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = self.flashMode
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func startMovieRecording() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                    let movieFileOutput = self.movieFileOutput,
                    !movieFileOutput.isRecording
            else {
                return
            }
            
            self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            
            let movieFileOutputConnection = movieFileOutput.connection(with: .video)
            movieFileOutputConnection?.videoOrientation = .portrait
            
            let availableVideoCodecTypes = movieFileOutput.availableVideoCodecTypes
            if availableVideoCodecTypes.contains(.hevc) {
                movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
            }
            
            let outputFileName = UUID().uuidString
            let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
            movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            
            self.publisher.send(.recordingVideoBegun)
        }
    }
    
    func stopVideoRecording() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                    let movieFileOutput = self.movieFileOutput,
                    movieFileOutput.isRecording
            else {
                return
            }
            
            movieFileOutput.stopRecording()
            self.publisher.send(.recordingVideoFinished)
        }
    }
    
    func checkCameraPermission() {
        let camPermStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch camPermStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                self?.camPermGranted = isGranted
            }
        case .restricted:
            break
        case .denied:
            camPermGranted = false
        case .authorized:
            camPermGranted = true
        @unknown default:
            break
        }
    }
    
    func checkMicrophonePermission() {
        let microphonePermStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        switch microphonePermStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] isGranted in
                self?.microphonePermGranted = isGranted
            }
        case .restricted:
            break
        case .denied:
            microphonePermGranted = false
        case .authorized:
            microphonePermGranted = true
        @unknown default:
            break
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension AVCamManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Fail to convert pixel buffer.")
            return
        }
        
        if let image = UIImage(data: imageData, scale: 1.0) {
            publisher.send(.photoTaken(photo: image))
        } else {
            print("Fail to convert to UIImage.")
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension AVCamManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let currentBackgroundRecordingID = backgroundRecordingID {
            backgroundRecordingID = UIBackgroundTaskIdentifier.invalid

            if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
            }
        }

        if let error = error {
            publisher.send(.recordingVideoFailure(err: error))
        } else {
            publisher.send(.processingVideoFinished(videoUrl: outputFileURL))
        }
    }
}
