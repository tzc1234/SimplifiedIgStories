//
//  AVCaptureCamera.swift
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
}

final class AVCaptureCamera: NSObject, Camera, PhotoCaptureDevice, VideoRecordDevice, AuxiliarySupportedCamera {
    private let statusPublisher = PassthroughSubject<CameraStatus, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    private(set) var cameraPosition: CameraPosition = .back
    
    private(set) lazy var videoPreviewLayer: CALayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "AVCamSessionQueue")
    
    private(set) var captureDevice: AVCaptureDevice?
    private(set) var movieFileOutput: AVCaptureMovieFileOutput?
    private(set) var photoOutput: AVCapturePhotoOutput?
}

extension AVCaptureCamera {
    func performOnSessionQueue(action: @escaping () -> Void) {
        sessionQueue.async { action() }
    }
    
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
                try camera.addVideoOutput()
                try camera.addPhotoOutput()
            }
            
            subscribeCaptureSessionNotifications()
        }
    }
    
    private func configureSession(action: (AVCaptureCamera) throws -> Void) {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        do {
            try action(self)
        } catch {
            let errMsg = (error as? CameraSetupError)?.errMsg ?? error.localizedDescription
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
}

extension AVCaptureCamera {
    private func addVideoInput() throws {
        let position = convertToCaptureDevicePosition(from: cameraPosition)
        guard let device = AVCaptureDevice
            .default(.builtInWideAngleCamera, for: .video, position: position) else {
                throw CameraSetupError.defaultVideoDeviceUnavailable
        }
        
        try setupFocusAndExposure(for: device)
        captureDevice = device

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                throw CameraSetupError.addVideoDeviceInputFailure
            }
            
            session.addInput(input)
        } catch CameraSetupError.addVideoDeviceInputFailure {
            throw CameraSetupError.addVideoDeviceInputFailure
        } catch {
            throw CameraSetupError.createVideoDeviceInputFailure(err: error)
        }
    }
    
    private func convertToCaptureDevicePosition(from position: CameraPosition) -> AVCaptureDevice.Position {
        switch position {
        case .back: return .back
        case .front: return .front
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
            throw CameraSetupError.defaultAudioDeviceUnavailable
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                throw CameraSetupError.addAudioDeviceInputFailure
            }
            
            session.addInput(input)
        } catch CameraSetupError.addAudioDeviceInputFailure {
            throw CameraSetupError.addAudioDeviceInputFailure
        } catch {
            throw CameraSetupError.createAudioDeviceInputFailure(err: error)
        }
    }
    
    private func addVideoOutput() throws {
        let output = AVCaptureMovieFileOutput()
        guard session.canAddOutput(output) else {
            throw CameraSetupError.addMovieFileOutputFailure
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
            throw CameraSetupError.addPhotoOutputFailure
        }
        
        session.addOutput(output)
        photoOutput = output
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
}
