//
//  PhotoTaker.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 12/02/2024.
//

import AVKit
import Combine

enum PhotoTakerStatus {
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
    var photoOutput: AVCapturePhotoOutput? { get }
    var performOnSessionQueue: (@escaping () -> Void) -> Void { get }
}

final class AVPhotoTaker: NSObject, PhotoTaker {
    private let statusPublisher = PassthroughSubject<PhotoTakerStatus, Never>()
    private var output: AVCapturePhotoOutput?
    
    private let device: PhotoCaptureDevice
    
    init(device: PhotoCaptureDevice) {
        self.device = device
    }
    
    func getStatusPublisher() -> AnyPublisher<PhotoTakerStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
    
    func takePhoto(on mode: CameraFlashMode) {
        device.performOnSessionQueue { [weak self] in
            guard let self else { return }
            
            addPhotoOutputIfNeeded()
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = convertToCaptureDeviceFlashMode(from: mode)
            device.photoOutput?.capturePhoto(with: settings, delegate: self)
        }
    }
    
    private func addPhotoOutputIfNeeded() {
        if output == nil {
            let output = AVCapturePhotoOutput()
            guard device.session.canAddOutput(output) else {
                return
            }
            
            device.session.addOutput(output)
            self.output = output
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
