//
//  VideoSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import Photos

class VideoSaver {
    var saveCompletedAction: (() -> Void)?
    
    init(saveCompletedAction: (() -> Void)? = nil) {
        self.saveCompletedAction = saveCompletedAction
    }
    
    func saveVideoToAlbum(_ videoUrl: URL) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
        } completionHandler: { isSaved, error in
            if let error = error {
                print("Save video error: \(error.localizedDescription)")
            } else if isSaved {
                // *** Note that: if used for a struct(SwiftUI), self can't be weak!
                // Weak self is for class.
                self.saveCompletedAction?()
            }
        }
    }
}
