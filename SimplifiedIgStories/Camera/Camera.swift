//
//  Camera.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/06/2022.
//

import AVKit
import Combine

enum CameraStatus: Equatable {
    case sessionStarted
    case sessionStopped
    case cameraSwitched(position: CameraPosition)
}

protocol Camera {
    var cameraPosition: CameraPosition { get }
    var videoPreviewLayer: CALayer { get }
    
    func getStatusPublisher() -> AnyPublisher<CameraStatus, Never>
    func startSession()
    func stopSession()
    func switchCamera()
}

protocol CaptureDevice {
    var cameraPosition: CameraPosition { get }
    var session: AVCaptureSession { get }
    var performOnSessionQueue: (@escaping () -> Void) -> Void { get }
}

final class AVCamera: NSObject, Camera, CaptureDevice, AuxiliarySupportedCamera {
    private let statusPublisher = PassthroughSubject<CameraStatus, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    private(set) var cameraPosition: CameraPosition = .back
    
    private(set) lazy var videoPreviewLayer: CALayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    private(set) var captureDevice: AVCaptureDevice?
    
    let session: AVCaptureSession
    private let makeCaptureDeviceInput: (AVCaptureDevice) throws -> AVCaptureInput
    let performOnSessionQueue: (@escaping () -> Void) -> Void
    
    init(session: AVCaptureSession = AVCaptureSession(),
         makeCaptureDeviceInput: @escaping (AVCaptureDevice) throws -> AVCaptureInput =
            AVCaptureDeviceInput.init(device:),
         performOnSessionQueue: @escaping (@escaping () -> Void) -> Void = { action in
            DispatchQueue(label: "AVCamSessionQueue").async { action() }
         }
    ) {
        self.session = session
        self.performOnSessionQueue = performOnSessionQueue
        self.makeCaptureDeviceInput = makeCaptureDeviceInput
    }
}

extension AVCamera {
    func performOnSessionQueue(action: @escaping () -> Void) {
        performOnSessionQueue(action)
    }
    
    func getStatusPublisher() -> AnyPublisher<CameraStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
    
    func startSession() {
        performOnSessionQueue { [weak self] in
            guard let self, !session.isRunning else { return }
            
            setupSessionIfNeeded()
            session.startRunning()
        }
    }
    
    private func setupSessionIfNeeded() {
        if captureDevice == nil {
            session.sessionPreset = .high
            
            do {
                try addInputs()
            } catch {
                let errMsg = (error as? CameraSetupError)?.errMsg ?? error.localizedDescription
                print(errMsg)
            }
            
            subscribeCaptureSessionNotifications()
        }
    }
    
    private func addInputs() throws {
        try addVideoInput()
        try addAudioInput()
    }
    
    func switchCamera() {
        performOnSessionQueue { [weak self] in
            guard let self else { return }
            
            switchCameraPosition()
            reAddInputs()
            
            statusPublisher.send(.cameraSwitched(position: cameraPosition))
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
    
    private func configureSession(action: (AVCamera) throws -> Void) {
        session.beginConfiguration()
        
        do {
            try action(self)
        } catch {
            let errMsg = (error as? CameraSetupError)?.errMsg ?? error.localizedDescription
            print(errMsg)
        }
        
        session.commitConfiguration()
    }
    
    func stopSession() {
        session.stopRunning()
    }
}

extension AVCamera {
    private func addVideoInput() throws {
        let position = convertToCaptureDevicePosition(from: cameraPosition)
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            throw CameraSetupError.defaultVideoDeviceUnavailable
        }
        
        try setupFocusAndExposure(for: device)
        captureDevice = device

        do {
            let input = try makeCaptureDeviceInput(device)
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
            let input = try makeCaptureDeviceInput(device)
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
