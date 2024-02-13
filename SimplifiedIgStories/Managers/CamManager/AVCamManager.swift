//
//  AVCamManager.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/06/2022.
//

import AVKit
import Combine

enum CameraPosition {
    case back
    case front
}

enum CameraFlashMode {
    case on
    case off
    case auto
}

protocol Camera {
    var cameraPosition: CameraPosition { get }
    var videoPreviewLayer: CALayer { get }
    
    func getStatusPublisher() -> AnyPublisher<CameraStatus, Never>
    func startSession()
    func stopSession()
    func switchCamera()
    
    func startVideoRecording()
    func stopVideoRecording()
    
    func focus(on point: CGPoint)
    func zoom(to factor: CGFloat)
}

final class AVCamManager: NSObject, Camera, PhotoCaptureDevice {
    private let statusPublisher = PassthroughSubject<CameraStatus, Never>()
    
    private(set) var cameraPosition: CameraPosition = .back
    
    private(set) lazy var videoPreviewLayer: CALayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    private let session = AVCaptureSession()
    let sessionQueue = DispatchQueue(label: "AVCamSessionQueue")
    
    private var videoDevice: AVCaptureDevice?
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private(set) var photoOutput: AVCapturePhotoOutput?
    
    private var backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
    private var subscriptions = Set<AnyCancellable>()
    
    private var captureDevicePosition: AVCaptureDevice.Position {
        convertToCaptureDevicePosition(from: cameraPosition)
    }
}

extension AVCamManager {
    func getStatusPublisher() -> AnyPublisher<CameraStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !session.isRunning else { return }
            
            setupSessionIfNeeded()
            session.startRunning()
        }
    }
    
    private func setupSessionIfNeeded() {
        if session.inputs.isEmpty {
            configureSession { camera in
                try camera.addInputs()
                try camera.setBackgroundAudioPreference()
                try camera.addVideoOutput()
                try camera.addPhotoOutput()
            }
            
            subscribeCaptureSessionNotifications()
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
        try addAudioInput()
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            switchCameraPosition()
            reAddInputs()
            
            statusPublisher.send(.cameraSwitched(camPosition: cameraPosition))
        }
    }
    
    private func switchCameraPosition() {
        cameraPosition = cameraPosition == .back ? .front : .back
    }
    
    private func reAddInputs() {
        removeAllCaptureInputs()
        configureSession { manager in
            try manager.addInputs()
        }
    }
    
    private func removeAllCaptureInputs() {
        for input in session.inputs {
            session.removeInput(input)
        }
    }
    
    func stopSession() {
        session.stopRunning()
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
            outputConnection.isVideoMirrored = cameraPosition == .front
            
            if movieFileOutput.availableVideoCodecTypes.contains(.hevc) {
                movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: outputConnection)
            }
            
            movieFileOutput.startRecording(to: getVideoOutputPath(), recordingDelegate: self)
            
            statusPublisher.send(.recordingVideoBegun)
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
            statusPublisher.send(.recordingVideoFinished)
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
        guard let device = AVCaptureDevice
            .default(.builtInWideAngleCamera, for: .video, position: captureDevicePosition) else {
                throw CamSetupError.defaultVideoDeviceUnavailable
        }
        
        try setupFocusAndExposure(for: device)
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
    
    private func setupFocusAndExposure(for device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        
        device.unlockForConfiguration()
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
            .sink { [weak statusPublisher] _ in
                statusPublisher?.send(.sessionStarted)
            }
            .store(in: &subscriptions)

        NotificationCenter
            .default
            .publisher(for: .AVCaptureSessionDidStopRunning, object: nil)
            .sink { [weak statusPublisher] _ in
                statusPublisher?.send(.sessionStopped)
            }
            .store(in: &subscriptions)
    }
    
    private func convertToCaptureDevicePosition(from position: CameraPosition) -> AVCaptureDevice.Position {
        switch position {
        case .back: return .back
        case .front: return .front
        }
    }
}

extension AVCamManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        invalidateBackgroundRecordingTask()
        
        if let error {
            statusPublisher.send(.processingVideoFailure(err: error))
            return
        }
        
        statusPublisher.send(.processingVideoFinished(videoUrl: outputFileURL))
    }
    
    private func invalidateBackgroundRecordingTask() {
        if backgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(backgroundRecordingID)
            backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
        }
    }
}
