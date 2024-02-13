//
//  CameraAuthorizationHandler.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 12/02/2024.
//

import AVFoundation
import Combine

protocol DeviceAuthorizationTracker {
    func getPublisher() -> AnyPublisher<Bool, Never>
    func startTracking()
}

final class AVCaptureDeviceAuthorizationTracker: DeviceAuthorizationTracker {
    private let authorizationPublisher = CurrentValueSubject<Bool, Never>(false)
    
    func getPublisher() -> AnyPublisher<Bool, Never> {
        authorizationPublisher.eraseToAnyPublisher()
    }
    
    private let mediaType: AVMediaType
    
    init(mediaType: AVMediaType) {
        self.mediaType = mediaType
    }
    
    func startTracking() {
        let status = AVCaptureDevice.authorizationStatus(for: mediaType)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: mediaType) { [weak authorizationPublisher] isAuthorized in
                authorizationPublisher?.send(isAuthorized)
            }
        }
        
        authorizationPublisher.send(status == .authorized)
    }
}
