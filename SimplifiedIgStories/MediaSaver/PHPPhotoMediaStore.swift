//
//  PHPPhotoMediaStore.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 09/02/2024.
//

import PhotosUI

final class PHPPhotoMediaStore: MediaStore {
    func saveImageData(_ data: Data) async throws {
        guard let image = UIImage(data: data) else {
            throw MediaStoreError.failed
        }
        
        try await save {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
    
    func saveVideo(for url: URL) async throws {
        try await save {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
    
    private func save(changeRequest: @escaping () -> Void) async throws {
        guard await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized else {
            throw MediaStoreError.noPermission
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges(changeRequest)
        } catch {
            throw MediaStoreError.failed
        }
    }
}
