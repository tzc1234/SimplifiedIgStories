//
//  PhotoTaker.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 12/02/2024.
//

import AVKit
import Combine

enum PhotoTakerStatus: Equatable {
    case addPhotoOutputFailure
    case photoTaken(photo: UIImage)
    case imageConvertingFailure
}

protocol PhotoTaker {
    func getStatusPublisher() -> AnyPublisher<PhotoTakerStatus, Never>
    func takePhoto(on flashMode: CameraFlashMode)
}

protocol PhotoCaptureDevice {
    var cameraPosition: CameraPosition { get }
    var session: AVCaptureSession { get }
    var performOnSessionQueue: (@escaping () -> Void) -> Void { get }
}

final class AVPhotoTaker: NSObject, PhotoTaker {
    private let statusPublisher = PassthroughSubject<PhotoTakerStatus, Never>()
    private var output: AVCapturePhotoOutput? {
        session.outputs.first(where: { $0 is AVCapturePhotoOutput }) as? AVCapturePhotoOutput
    }
    private var session: AVCaptureSession {
        device.session
    }
    
    private let device: PhotoCaptureDevice
    private let makeCapturePhotoOutput: () -> AVCapturePhotoOutput
    
    init(device: PhotoCaptureDevice, 
         makeCapturePhotoOutput: @escaping () -> AVCapturePhotoOutput = AVCapturePhotoOutput.init) {
        self.device = device
        self.makeCapturePhotoOutput = makeCapturePhotoOutput
    }
    
    func getStatusPublisher() -> AnyPublisher<PhotoTakerStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
    
    func takePhoto(on flashMode: CameraFlashMode) {
        device.performOnSessionQueue { [weak self] in
            self?.addPhotoOutputIfNeeded()
            self?.capturePhoto(on: flashMode)
        }
    }
    
    private func addPhotoOutputIfNeeded() {
        guard output == nil else {
            return
        }
        
        session.beginConfiguration()
        
        let output = makeCapturePhotoOutput()
        guard session.canAddOutput(output) else {
            statusPublisher.send(.addPhotoOutputFailure)
            return
        }
        
        session.addOutput(output)
        session.commitConfiguration()
    }
    
    private func capturePhoto(on flashMode: CameraFlashMode) {
        guard session.isRunning else { return }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = convertToCaptureDeviceFlashMode(from: flashMode)
        output?.capturePhoto(with: settings, delegate: self)
    }
    
    private func convertToCaptureDeviceFlashMode(from flashMode: CameraFlashMode) -> AVCaptureDevice.FlashMode {
        switch flashMode {
        case .on: return .on
        case .off: return .off
        case .auto: return .auto
        }
    }
}

extension AVPhotoTaker: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = makeImage(from: data) else {
            statusPublisher.send(.imageConvertingFailure)
            return
        }
        
        statusPublisher.send(.photoTaken(photo: image))
    }
    
    private func makeImage(from data: Data) -> UIImage? {
        guard let image = UIImage(data: data, scale: 1.0) else {
            return nil
        }
        
        guard device.cameraPosition == .front, let cgImage = image.cgImage else {
            return image
        }
        
        let flippedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
        return flippedImage
    }
}
