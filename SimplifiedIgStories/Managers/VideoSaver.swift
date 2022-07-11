//
//  VideoSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import PhotosUI

class VideoSaver {
    func saveToAlbum(_ videoUrl: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
                    } completionHandler: { isSaved, error in
                        if let error = error {
                            continuation.resume(throwing: ImageVideoSaveError.saveError(error))
                        } else if isSaved {
                            continuation.resume(returning: "Saved.")
                        }
                    }
                } else {
                    continuation.resume(throwing: ImageVideoSaveError.noAddPhotoPermission)
                }
            }
        }
    }
}
