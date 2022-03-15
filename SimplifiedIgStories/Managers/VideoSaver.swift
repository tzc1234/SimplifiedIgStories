//
//  VideoSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import PhotosUI

class VideoSaver {
    let completion: ImageVideoSaveCompletion
    
    init(completion: ImageVideoSaveCompletion = nil) {
        self.completion = completion
    }
    
    func saveVideoToAlbum(_ videoUrl: URL) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
                } completionHandler: { isSaved, error in
                    if let error = error {
                        self.completion?(.failure(.saveError(error)))
                    } else if isSaved {
                        self.completion?(.success("Saved."))
                    }
                }
            } else {
                self.completion?(.failure(.noAddPhotoPermission))
            }
        }
    }
}
