//
//  MediaSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import PhotosUI

// MARK: - MediaSaveError
enum MediaSavingError: Error {
    case noAddPhotoPermission
    
    var errMsg: String {
        switch self {
        case .noAddPhotoPermission:
            return "Couldn't save. No add photo permission."
        }
    }
}

// MARK: - MediaSaver
protocol MediaSaver {
    typealias SuccessMsgStr = String
    
    func saveToAlbum(_ image: UIImage) async throws -> SuccessMsgStr
    func saveToAlbum(_ videoUrl: URL) async throws -> SuccessMsgStr
}

// MARK: - MediaFileSaver
struct MediaFileSaver: MediaSaver {
    func saveToAlbum(_ image: UIImage) async throws -> SuccessMsgStr {
        try await save {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
    
    func saveToAlbum(_ videoUrl: URL) async throws -> SuccessMsgStr {
        try await save {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
        }
    }
    
    private func save(changeRequest: @escaping () -> Void) async throws -> SuccessMsgStr {
        guard await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized else {
            throw MediaSavingError.noAddPhotoPermission
        }
        
        try await PHPhotoLibrary.shared().performChanges(changeRequest)
            
        return "Saved."
    }
}
