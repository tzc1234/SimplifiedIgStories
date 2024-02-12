//
//  PhotoTaker.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 12/02/2024.
//

import AVFoundation
import Combine
import UIKit

enum PhotoTakerStatus {
    case photoTaken(photo: UIImage)
    case imageConvertingFailure
}

protocol PhotoTaker {
    func getStatusPublisher() -> AnyPublisher<PhotoTakerStatus, Never>
    func takePhoto(on mode: CameraFlashMode, cameraPosition: CameraPosition)
}

final class AVCapturePhotoTaker: NSObject, PhotoTaker {
    private let statusPublisher = PassthroughSubject<PhotoTakerStatus, Never>()
    private var shouldFlipImage = false
    
    private let output: AVCapturePhotoOutput
    private let session: AVCaptureSession
    private let sessionQueue: DispatchQueue
    
    init?(session: AVCaptureSession, sessionQueue: DispatchQueue) {
        let output = AVCapturePhotoOutput()
        guard session.canAddOutput(output) else {
            return nil
        }
        
        session.addOutput(output)
        
        self.output = output
        self.session = session
        self.sessionQueue = sessionQueue
        super.init()
    }
    
    func getStatusPublisher() -> AnyPublisher<PhotoTakerStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
    
    func takePhoto(on mode: CameraFlashMode, cameraPosition: CameraPosition) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            shouldFlipImage = cameraPosition == .front
            let settings = AVCapturePhotoSettings()
            settings.flashMode = convertToCaptureDeviceFlashMode(from: mode)
            output.capturePhoto(with: settings, delegate: self)
        }
    }
    
    private func convertToCaptureDeviceFlashMode(from flashMode: CameraFlashMode) -> AVCaptureDevice.FlashMode {
        switch flashMode {
        case .on: return .on
        case .off: return .off
        case .auto: return .auto
        }
    }
    
    deinit {
        session.removeOutput(output)
    }
}

extension AVCapturePhotoTaker: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error != nil, let data = photo.fileDataRepresentation(), let image = makeImage(from: data) else {
            statusPublisher.send(.imageConvertingFailure)
            return
        }
        
        statusPublisher.send(.photoTaken(photo: image))
    }
    
    private func makeImage(from data: Data) -> UIImage? {
        guard let image = UIImage(data: data, scale: 1.0) else {
            return nil
        }
        
        guard shouldFlipImage, let cgImage = image.cgImage else {
            return image
        }
        
        let flippedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
        return flippedImage
    }
}
