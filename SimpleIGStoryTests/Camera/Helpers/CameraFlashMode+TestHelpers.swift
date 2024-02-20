//
//  CameraFlashMode+TestHelpers.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 20/02/2024.
//

import AVFoundation
@testable import Simple_IG_Story

extension CameraFlashMode {
    func toCaptureDeviceFlashMode() -> AVCaptureDevice.FlashMode {
        switch self {
        case .on: return .on
        case .off: return .off
        case .auto: return .auto
        }
    }
}
