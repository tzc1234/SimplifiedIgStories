//
//  CameraPosition+TestHelpers.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 20/02/2024.
//

import AVFoundation
@testable import Simple_IG_Story

extension CameraPosition {
    func toCaptureDevicePosition() -> AVCaptureDevice.Position {
        switch self {
        case .back: return .back
        case .front: return .front
        }
    }
    
    func toggle() -> CameraPosition {
        self == .back ? .front : .back
    }
}
