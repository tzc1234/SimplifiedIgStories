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
    func takePhoto(on mode: CameraFlashMode)
}

protocol PhotoCaptureDevice {
    var cameraPosition: CameraPosition { get }
    var session: AVCaptureSession { get }
    var performOnSessionQueue: (@escaping () -> Void) -> Void { get }
}

final class AVPhotoTaker: NSObject, PhotoTaker {
    private let statusPublisher = PassthroughSubject<PhotoTakerStatus, Never>()
    private var output: AVCapturePhotoOutput?
    
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
    
    func takePhoto(on mode: CameraFlashMode) {
        device.performOnSessionQueue { [weak self] in
            guard let self, device.session.isRunning else { return }
            
            addPhotoOutputIfNeeded()
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = convertToCaptureDeviceFlashMode(from: mode)
            output?.capturePhoto(with: settings, delegate: self)
        }
    }
    
    private func addPhotoOutputIfNeeded() {
        if output == nil {
            device.session.beginConfiguration()
            
            let output = makeCapturePhotoOutput()
            guard device.session.canAddOutput(output) else {
                statusPublisher.send(.addPhotoOutputFailure)
                return
            }
            
            device.session.addOutput(output)
            self.output = output
            
            device.session.commitConfiguration()
        }
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
