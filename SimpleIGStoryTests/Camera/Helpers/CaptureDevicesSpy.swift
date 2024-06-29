//
//  CaptureDevicesSpy.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 29/06/2024.
//

import AVFoundation

final class CaptureDevicesSpy {
    private(set) var loggedDevices = [AVCaptureDevice]()
    var loggedDeviceTypes: Set<AVMediaType?> {
        Set(loggedDevices.map(\.type))
    }
    
    func resetLoggings() {
        loggedDevices.removeAll()
    }
    
    func makeCaptureInput(device: AVCaptureDevice) throws -> AVCaptureInput {
        loggedDevices.append(device)
        return makeDummyCaptureInput()
    }
    
    private func makeDummyCaptureInput() -> AVCaptureInput {
        let klass = AVCaptureInput.self as NSObject.Type
        return klass.init() as! AVCaptureInput
    }
}
