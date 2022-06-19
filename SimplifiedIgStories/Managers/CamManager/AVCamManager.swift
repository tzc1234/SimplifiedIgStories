//
//  AVCamManager.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/06/2022.
//

import AVFoundation
import Combine
import UIKit

// MARK: - CamManager
protocol CamManager {
    var camPermPublisher: CurrentValueSubject<Bool, Never> { get }
    var microphonePermPublisher: CurrentValueSubject<Bool, Never> { get }
    var camStatusPublisher: PassthroughSubject<CamStatus, Never> { get }
    
    var session: AVCaptureSession { get }
    var camPosition: AVCaptureDevice.Position { get set }
    var flashMode: AVCaptureDevice.FlashMode { get set }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { get }
    
    func setupSession()
    func switchCamera()
    func takePhoto()
    func startVideoRecording()
    func stopVideoRecording()
    func checkPermissions()
}

// MARK: - AVCamManager
final class AVCamManager: NSObject, CamManager {
    private(set) var camPermPublisher = CurrentValueSubject<Bool, Never>(false)
    private(set) var microphonePermPublisher = CurrentValueSubject<Bool, Never>(false)
    let camStatusPublisher = PassthroughSubject<CamStatus, Never>()
    
    let session = AVCaptureSession()
    var camPosition: AVCaptureDevice.Position = .back
    var flashMode: AVCaptureDevice.FlashMode = .off
    
    private(set) lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    private let sessionQueue = DispatchQueue(label: "AVCamSessionQueue")
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    private var subscriptions = Set<AnyCancellable>()
}

// MARK: - internal functions
extension AVCamManager {
    func setupSession() {
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
            self.subscribeCaptureSessionNotifications()
            self.session.startRunning()
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Remove all inputs first.
            for input in self.session.inputs {
                self.session.removeInput(input)
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            // Re-add inputs.
            do {
                try self.addVideoInput()
                try self.addAudioInput()
            } catch {
                let errMsg = (error as? CamSetupError)?.errMsg ?? error.localizedDescription
                print(errMsg)
            }
            
            self.session.commitConfiguration()
            self.camStatusPublisher.send(.cameraSwitched(camPosition: self.camPosition))
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
    
    func startVideoRecording() {
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
            
            self.camStatusPublisher.send(.recordingVideoBegun)
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
            self.camStatusPublisher.send(.recordingVideoFinished)
        }
    }
    
    func checkPermissions() {
        checkCameraPermission()
        checkMicrophonePermission()
    }
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
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                self?.camPermPublisher.send(isGranted)
            }
        case .restricted:
            break
        case .denied:
            camPermPublisher.send(false)
        case .authorized:
            camPermPublisher.send(true)
        @unknown default:
            break
        }
    }
    
    private func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] isGranted in
                self?.microphonePermPublisher.send(isGranted)
            }
        case .restricted:
            break
        case .denied:
            microphonePermPublisher.send(false)
        case .authorized:
            microphonePermPublisher.send(true)
        @unknown default:
            break
        }
    }
    
    private func subscribeCaptureSessionNotifications() {
        NotificationCenter
            .default
            .publisher(for: .AVCaptureSessionDidStartRunning, object: nil)
            .sink { [weak self] _ in
                self?.camStatusPublisher.send(.sessionStarted)
            }
            .store(in: &subscriptions)

        NotificationCenter
            .default
            .publisher(for: .AVCaptureSessionDidStopRunning, object: nil)
            .sink { [weak self] _ in
                self?.camStatusPublisher.send(.sessionStopped)
            }
            .store(in: &subscriptions)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension AVCamManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            camStatusPublisher.send(.processingPhotoFailure(err: error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            camStatusPublisher.send(.processingPhotoDataFailure)
            return
        }
        
        guard let image = UIImage(data: imageData, scale: 1.0) else {
            camStatusPublisher.send(.convertToUIImageFailure)
            return
        }
        
        camStatusPublisher.send(.photoTaken(photo: image))
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
            camStatusPublisher.send(.processingVideoFailure(err: error))
        } else {
            camStatusPublisher.send(.processingVideoFinished(videoUrl: outputFileURL))
        }
    }
}
