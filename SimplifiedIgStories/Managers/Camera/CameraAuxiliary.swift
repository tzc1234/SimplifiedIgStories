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
}

protocol CameraAuxiliary {
    func focus(on point: CGPoint)
    func zoom(to factor: CGFloat)
}

protocol AuxiliarySupportedCamera {
    var captureDevice: AVCaptureDevice? { get }
    var performOnSessionQueue: (@escaping () -> Void) -> Void { get }
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

        camera.performOnSessionQueue { [weak self] in
            do {
                try self?.configureVideoDevice { device in
                    if device.isFocusPointOfInterestSupported {
                        device.focusPointOfInterest = focusPoint
                    }
                    
                    if device.isFocusModeSupported(.autoFocus) {
                        device.focusMode = .autoFocus
                    }
                    
//                    if device.isExposurePointOfInterestSupported &&
//                        device.isExposureModeSupported(.continuousAutoExposure) {
//                        device.exposurePointOfInterest = focusPoint
//                        device.exposureMode = .continuousAutoExposure
//                    }
                }
            } catch {
                print("Cannot lock device for configuration: \(error)")
            }
        }
    }
    
    func zoom(to factor: CGFloat) {
//        camera.performOnSessionQueue { [weak self] in
//            do {
//                try self?.configureVideoDevice { device in
//                    // Reference: https://stackoverflow.com/a/43278702
//                    let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
//                    device.videoZoomFactor = max(1.0, min(device.videoZoomFactor + factor, maxZoomFactor))
//                }
//            } catch {
//                print("Cannot lock device for configuration: \(error)")
//            }
//        }
    }
    
    private func configureVideoDevice(action: (AVCaptureDevice) -> Void) throws {
        guard let device = camera.captureDevice else {
            statusPublisher.send(.captureDeviceNotFound)
            return
        }
        
//        try device.lockForConfiguration()
        action(device)
//        device.unlockForConfiguration()
    }
}
