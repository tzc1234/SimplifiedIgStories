//
//  VideoSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import PhotosUI
import Combine

class VideoSaver {
    func saveToAlbum(_ videoUrl: URL) -> AnyPublisher<String, ImageVideoSaveError> {
        Future<String, ImageVideoSaveError> { promise in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
                    } completionHandler: { isSaved, error in
                        if let error = error {
                            promise(.failure(.saveError(error)))
                        } else if isSaved {
                            promise(.success("Saved."))
                        }
                    }
                } else {
                    promise(.failure(.noAddPhotoPermission))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
