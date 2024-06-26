//
//  CameraAuxiliary.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 13/02/2024.
//

import AVKit
import Combine

enum CameraAuxiliaryStatus {
    case captureDeviceNotFound
    case changeDeviceSettingsFailure
}

protocol CameraAuxiliary {
    func focus(on point: CGPoint)
    func zoom(to factor: CGFloat)
}

protocol AuxiliarySupportedCamera {
    var captureDevice: AVCaptureDevice? { get }
}

final class AVCameraAuxiliary: CameraAuxiliary {
    private let statusPublisher = PassthroughSubject<CameraAuxiliaryStatus, Never>()
    
    private let camera: AuxiliarySupportedCamera
    
    init(camera: AuxiliarySupportedCamera) {
        self.camera = camera
    }
    
    func getStatusPublisher() -> AnyPublisher<CameraAuxiliaryStatus, Never> {
        statusPublisher.eraseToAnyPublisher()
    }
    
    func focus(on point: CGPoint) {
        let x = point.y / .screenHeight
        let y = 1.0 - point.x / .screenWidth
        let focusPoint = CGPoint(x: x, y: y)

        configureCaptureDevice { device in
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
            }
            
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
            }
            
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
        }
    }
    
    func zoom(to factor: CGFloat) {
        configureCaptureDevice { device in
            // Reference: https://stackoverflow.com/a/43278702
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            device.videoZoomFactor = max(1.0, min(device.videoZoomFactor + factor, maxZoomFactor))
        }
    }
    
    private func configureCaptureDevice(action: (AVCaptureDevice) -> Void) {
        guard let device = camera.captureDevice else {
            statusPublisher.send(.captureDeviceNotFound)
            return
        }
        
        do {
            try device.lockForConfiguration()
            action(device)
            device.unlockForConfiguration()
        } catch {
            statusPublisher.send(.changeDeviceSettingsFailure)
        }
    }
}
