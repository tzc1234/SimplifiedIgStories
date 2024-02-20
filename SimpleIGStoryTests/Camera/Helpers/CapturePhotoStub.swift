//
//  CapturePhotoStub.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 20/02/2024.
//

import AVFoundation

final class CapturePhotoStub: AVCapturePhoto {
    var fileData: Data?
    
    override func fileDataRepresentation() -> Data? {
        fileData
    }
}
