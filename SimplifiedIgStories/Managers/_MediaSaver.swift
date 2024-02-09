//
//  _MediaSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import PhotosUI

enum MediaSavingError: Error {
    case noAddPhotoPermission
    
    var errMsg: String {
        switch self {
        case .noAddPhotoPermission:
            return "Couldn't save. No add photo permission."
        }
    }
}

protocol _MediaSaver {
    typealias SuccessMessage = String
    
    func saveToAlbum(_ image: UIImage) async throws -> SuccessMessage
    func saveToAlbum(_ videoURL: URL) async throws -> SuccessMessage
}

struct MediaFileSaver: _MediaSaver {
    func saveToAlbum(_ image: UIImage) async throws -> SuccessMessage {
        try await save {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
    
    func saveToAlbum(_ videoURL: URL) async throws -> SuccessMessage {
        try await save {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }
    }
    
    private func save(changeRequest: @escaping () -> Void) async throws -> SuccessMessage {
        guard await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized else {
            throw MediaSavingError.noAddPhotoPermission
        }
        
        try await PHPhotoLibrary.shared().performChanges(changeRequest)
            
        return "Saved."
    }
}
