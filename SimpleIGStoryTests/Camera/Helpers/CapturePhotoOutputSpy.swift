//
//  CapturePhotoOutputSpy.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 20/02/2024.
//

import AVFoundation

final class CapturePhotoOutputSpy: AVCapturePhotoOutput {
    private struct CapturePhotoParam {
        let settings: AVCapturePhotoSettings
        weak var delegate: AVCapturePhotoCaptureDelegate?
    }
    
    private var loggedCapturePhotoParams = [CapturePhotoParam]()
    var capturePhotoCallCount: Int {
        loggedCapturePhotoParams.count
    }
    var loggedSettings: [AVCapturePhotoSettings] {
        loggedCapturePhotoParams.map(\.settings)
    }
    var loggedDelegates: [AVCapturePhotoCaptureDelegate] {
        loggedCapturePhotoParams.compactMap(\.delegate)
    }
    
    override func capturePhoto(with settings: AVCapturePhotoSettings, delegate: AVCapturePhotoCaptureDelegate) {
        loggedCapturePhotoParams.append(CapturePhotoParam(settings: settings, delegate: delegate))
    }
}
