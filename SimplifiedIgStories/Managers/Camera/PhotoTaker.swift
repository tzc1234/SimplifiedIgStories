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
    var photoOutput: AVCapturePhotoOutput? { get }
    var sessionQueue: DispatchQueue { get }
}

final class AVCapturePhotoTaker: NSObject, PhotoTaker {
    private let statusPublisher = PassthroughSubject<PhotoTakerStatus, Never>()
    
    private let device: PhotoCaptureDevice
    
    init(device: PhotoCaptureDevice) {
        self.device = device
    }
    
    func getStatusPublisher() -> AnyPublisher<PhotoTakerStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
    
    func takePhoto(on mode: CameraFlashMode) {
        device.sessionQueue.async { [weak self] in
            guard let self else { return }
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = convertToCaptureDeviceFlashMode(from: mode)
            device.photoOutput?.capturePhoto(with: settings, delegate: self)
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

extension AVCapturePhotoTaker: AVCapturePhotoCaptureDelegate {
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
