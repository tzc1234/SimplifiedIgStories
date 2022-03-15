//
//  ImageSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import UIKit
import PhotosUI

enum ImageVideoSaveError: Error {
    case noAddPhotoPermission
    case saveError(Error)
}

typealias ImageVideoSaveCompletion = ((Result<String, ImageVideoSaveError>) -> Void)?

class ImageSaver: NSObject {
    let completion: ImageVideoSaveCompletion
    
    init(completion: ImageVideoSaveCompletion = nil) {
        self.completion = completion
    }
    
    func saveImageToAlbum(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(ImageSaver.performSaveImage), nil)
            } else {
                self.completion?(.failure(.noAddPhotoPermission))
            }
        }
    }
    
    @objc private func performSaveImage(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            completion?(.failure(.saveError(error)))
        } else {
            completion?(.success("Saved."))
        }
    }
}
