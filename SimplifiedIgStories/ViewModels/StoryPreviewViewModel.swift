//
//  StoryPreviewViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 03/07/2024.
//

import UIKit

final class StoryPreviewViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var message = ""
    
    private let mediaSaver: MediaSaver
    
    init(mediaSaver: MediaSaver) {
        self.mediaSaver = mediaSaver
    }
    
    @MainActor
    func saveToAlbum(image: UIImage) async {
        isLoading = true
        message = ""
        
        if let data = image.jpegData(compressionQuality: 1) {
            do {
                try await mediaSaver.saveImageData(data)
                message = "Saved."
            } catch MediaSaverError.noPermission {
                message = "Couldn't save. No add photo permission."
            } catch {
                message = "Save failed."
            }
        }
        
        isLoading = false
    }
    
    @MainActor
    func saveToAlbum(videoURL: URL) async {
        isLoading = true
        message = ""
        
        do {
            try await mediaSaver.saveVideo(by: videoURL)
            message = "Saved."
        } catch MediaSaverError.noPermission {
            message = "Couldn't save. No add photo permission."
        } catch {
            message = "Save failed."
        }
        
        isLoading = false
    }
}
