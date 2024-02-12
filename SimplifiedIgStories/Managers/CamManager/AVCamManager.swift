//
//  AVCamManager.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/06/2022.
//

import AVFoundation
import Combine
import UIKit

protocol CamManager: AnyObject {
    var camStatusPublisher: PassthroughSubject<CamStatus, Never> { get }
    
    var camPosition: AVCaptureDevice.Position { get }
    var flashMode: AVCaptureDevice.FlashMode { get set }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { get }
    
    func setupAndStartSession()
    func startSession()
    func stopSession()
    func switchCamera()
    func takePhoto()
    func startVideoRecording()
    func stopVideoRecording()
    
    func focus(on point: CGPoint)
    func zoom(to factor: CGFloat)
}

final class AVCamManager: NSObject, CamManager {
    let camStatusPublisher = PassthroughSubject<CamStatus, Never>()
    
    private(set) var camPosition: AVCaptureDevice.Position = .back
    var flashMode: AVCaptureDevice.FlashMode = .off
    
    private(set) lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "AVCamSessionQueue")
    
    private var videoDevice: AVCaptureDevice?
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var photoOutput: AVCapturePhotoOutput?
    
    private var backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
    private var subscriptions = Set<AnyCancellable>()
}

extension AVCamManager {
    func setupAndStartSession() {
        sessionQueue.async { [weak self] in
            guard let self, !session.isRunning else { return }
            
            configureSession { manager in
                try manager.addInputs()
                try manager.setBackgroundAudioPreference()
                try manager.addVideoOutput()
                try manager.addPhotoOutput()
            }
            
            subscribeCaptureSessionNotifications()
            session.startRunning()
        }
    }
    
    private func configureSession(action: (AVCamManager) throws -> Void) {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        do {
            try action(self)
        } catch {
            let errMsg = (error as? CamSetupError)?.errMsg ?? error.localizedDescription
            print(errMsg)
        }
        
        session.commitConfiguration()
    }
    
    private func addInputs() throws {
        try addVideoInput()
        try setupFocusAndExposure()
        try addAudioInput()
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            switchCameraPosition()
            removeAllCaptureInputs()
            reAddInputs()
            
            camStatusPublisher.send(.cameraSwitched(camPosition: camPosition))
        }
    }
    
    private func switchCameraPosition() {
        camPosition = camPosition == .back ? .front : .back
    }
    
    private func reAddInputs() {
        configureSession { manager in
            try manager.addInputs()
        }
    }
    
    private func removeAllCaptureInputs() {
        for input in session.inputs {
            session.removeInput(input)
        }
    }
    
    func startSession() {
        session.startRunning()
    }
    
    func stopSession() {
        session.stopRunning()
    }
    
    func takePhoto() {
        sessionQueue.async { [weak self] in
            guard let self, let photoOutput else {
                return
            }
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = flashMode
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func startVideoRecording() {
        sessionQueue.async { [weak self] in
            guard let self, let movieFileOutput, !movieFileOutput.isRecording else {
                return
            }
            
            backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            
            guard let outputConnection = movieFileOutput.connection(with: .video) else {
                return
            }
            
            outputConnection.videoOrientation = .portrait
            outputConnection.isVideoMirrored = camPosition == .front
            
            if movieFileOutput.availableVideoCodecTypes.contains(.hevc) {
                movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: outputConnection)
            }
            
            movieFileOutput.startRecording(to: getVideoOutputPath(), recordingDelegate: self)
            
            camStatusPublisher.send(.recordingVideoBegun)
        }
    }
    
    private func getVideoOutputPath() -> URL {
        let fileName = UUID().uuidString
        return FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
            .appendingPathExtension("mov")
    }
    
    func stopVideoRecording() {
        sessionQueue.async { [weak self] in
            guard let self, let movieFileOutput, movieFileOutput.isRecording else {
                return
            }
            
            movieFileOutput.stopRecording()
            camStatusPublisher.send(.recordingVideoFinished)
        }
    }
    
    func focus(on point: CGPoint) {
        let x = point.y / .screenHeight
        let y = 1.0 - point.x / .screenWidth
        let focusPoint = CGPoint(x: x, y: y)

        sessionQueue.async { [weak self] in
            do {
                try self?.configureVideoDevice { device in
                    if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusPointOfInterest = focusPoint
                        device.focusMode = .autoFocus
                    }
                    
                    if device.isExposurePointOfInterestSupported && 
                        device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposurePointOfInterest = focusPoint
                        device.exposureMode = .continuousAutoExposure
                    }
                }
            } catch {
                print("Cannot lock device for configuration: \(error)")
            }
        }
    }
    
    func zoom(to factor: CGFloat) {
        sessionQueue.async { [weak self] in
            do {
                try self?.configureVideoDevice { device in
                    // Reference: https://stackoverflow.com/a/43278702
                    let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
                    device.videoZoomFactor = max(1.0, min(device.videoZoomFactor + factor, maxZoomFactor))
                }
            } catch {
                print("Cannot lock device for configuration: \(error)")
            }
        }
    }
    
    private func configureVideoDevice(action: (AVCaptureDevice) -> Void) throws {
        guard let videoDevice else {
            throw CamSetupError.videoDeviceNotFound
        }
        
        try videoDevice.lockForConfiguration()
        action(videoDevice)
        videoDevice.unlockForConfiguration()
    }
}

extension AVCamManager {
    private func addVideoInput() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: camPosition) else {
            throw CamSetupError.defaultVideoDeviceUnavailable
        }
        
        videoDevice = device

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                throw CamSetupError.addVideoDeviceInputFailure
            }
            
            session.addInput(input)
            videoDeviceInput = input
        } catch CamSetupError.addVideoDeviceInputFailure {
            throw CamSetupError.addVideoDeviceInputFailure
        } catch {
            throw CamSetupError.createVideoDeviceInputFailure(err: error)
        }
    }
    
    private func setupFocusAndExposure() throws {
        try configureVideoDevice { device in
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }

            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
        }
    }
    
    private func addAudioInput() throws {
        guard let device = AVCaptureDevice.default(for: .audio) else {
            throw CamSetupError.defaultAudioDeviceUnavailable
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                throw CamSetupError.addAudioDeviceInputFailure
            }
            
            session.addInput(input)
        } catch CamSetupError.addAudioDeviceInputFailure {
            throw CamSetupError.addAudioDeviceInputFailure
        } catch {
            throw CamSetupError.createAudioDeviceInputFailure(err: error)
        }
    }
    
    private func addVideoOutput() throws {
        let output = AVCaptureMovieFileOutput()
        guard session.canAddOutput(output) else {
            throw CamSetupError.addMovieFileOutputFailure
        }
        
        session.addOutput(output)

        if let connection = output.connection(with: .video), connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
        
        movieFileOutput = output
    }
    
    private func addPhotoOutput() throws {
        let output = AVCapturePhotoOutput()
        guard session.canAddOutput(output) else {
            throw CamSetupError.addPhotoOutputFailure
        }
        
        session.addOutput(output)
        photoOutput = output
    }
    
    private func setBackgroundAudioPreference() throws {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            throw CamSetupError.backgroundAudioPreferenceSetupFailure
        }
    }
    
    private func subscribeCaptureSessionNotifications() {
        NotificationCenter
            .default
            .publisher(for: .AVCaptureSessionDidStartRunning, object: nil)
            .sink { [weak camStatusPublisher] _ in
                camStatusPublisher?.send(.sessionStarted)
            }
            .store(in: &subscriptions)

        NotificationCenter
            .default
            .publisher(for: .AVCaptureSessionDidStopRunning, object: nil)
            .sink { [weak camStatusPublisher] _ in
                camStatusPublisher?.send(.sessionStopped)
            }
            .store(in: &subscriptions)
    }
}

extension AVCamManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            camStatusPublisher.send(.processingPhotoFailure(err: error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            camStatusPublisher.send(.processingPhotoDataFailure)
            return
        }
        
        guard let image = makeImage(from: imageData) else {
            camStatusPublisher.send(.convertToUIImageFailure)
            return
        }
        
        camStatusPublisher.send(.photoTaken(photo: image))
    }
    
    private func makeImage(from data: Data) -> UIImage? {
        guard let image = UIImage(data: data, scale: 1.0) else {
            return nil
        }
        
        guard camPosition == .front, let cgImage = image.cgImage else {
            return image
        }
        
        let flippedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
        return flippedImage
    }
}

extension AVCamManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        invalidateBackgroundRecordingTask()
        
        if let error {
            camStatusPublisher.send(.processingVideoFailure(err: error))
            return
        }
        
        camStatusPublisher.send(.processingVideoFinished(videoUrl: outputFileURL))
    }
    
    private func invalidateBackgroundRecordingTask() {
        if backgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(backgroundRecordingID)
            backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
        }
    }
}
