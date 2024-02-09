//
//  PHPPhotoMediaStore.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 09/02/2024.
//

/*
    This class is not tested because every time have to ensure there is an add photo permission,
    it makes the test flaky. And also this class is simple enough not testing.
*/

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
    
    func saveVideo(by url: URL) async throws {
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
