//
//  ImageSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import UIKit
import PhotosUI
import Combine

enum ImageVideoSaveError: Error {
    case noAddPhotoPermission
    case saveError(Error)
}

typealias ImageVideoSaveCompletion = ((Result<String, ImageVideoSaveError>) -> Void)?

class ImageSaver: NSObject {
    private var completion: ImageVideoSaveCompletion = nil
    
    func saveToAlbum(_ image: UIImage) -> AnyPublisher<String, ImageVideoSaveError> {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(ImageSaver.performSaveImage), nil)
            } else {
                self.completion?(.failure(.noAddPhotoPermission))
            }
        }
        
        return Future<String, ImageVideoSaveError> { [weak self] promise in
            self?.completion = { result in
                switch result {
                case .success(let str):
                    promise(.success(str))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    @objc private func performSaveImage(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            completion?(.failure(.saveError(error)))
        } else {
            completion?(.success("Saved."))
        }
    }
}
