//
//  ImageSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import UIKit
import PhotosUI

// MARK: - ImageVideoSaveError
enum ImageVideoSaveError: Error {
    case noAddPhotoPermission
    case saveError(Error)
    
    var errMsg: String {
        switch self {
        case .noAddPhotoPermission:
            return "Couldn't save. No add photo permission."
        case .saveError(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - ImageSaver
struct ImageSaver {
    func saveToAlbum(_ image: UIImage) async throws -> String {
        try await Coordinator().saveToAlbum(image)
    }
    
    private class Coordinator: NSObject {
        private var saveImageContinuation: CheckedContinuation<String, Error>?
        
        func saveToAlbum(_ image: UIImage) async throws -> String {
            return try await withCheckedThrowingContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
                    if status == .authorized {
                        self?.saveImageContinuation = continuation
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(Coordinator.performSaveImage), nil)
                    } else {
                        continuation.resume(throwing: ImageVideoSaveError.noAddPhotoPermission)
                    }
                }
            }
        }
        
        @objc private func performSaveImage(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            if let error = error {
                saveImageContinuation?.resume(throwing: ImageVideoSaveError.saveError(error))
            } else {
                saveImageContinuation?.resume(returning: "Saved.")
            }
            saveImageContinuation = nil
        }
    }
}
