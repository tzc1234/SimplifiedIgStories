//
//  StoryPortionViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/03/2022.
//

import UIKit

final class StoryPortionViewModel: ObservableObject {
    @Published var showConfirmationDialog = false
    @Published private(set) var isLoading = false
    @Published private(set) var noticeMsg = ""
    
    let storyId: Int
    let isCurrentUser: Bool
    let portion: Portion
    private let fileManager: FileManageable
    private let mediaSaver: MediaSaver
    
    init(story: Story,
         portion: Portion,
         fileManager: FileManageable,
         mediaSaver: MediaSaver) {
        self.storyId = story.id
        self.isCurrentUser = story.user.isCurrentUser
        self.portion = portion
        self.fileManager = fileManager
        self.mediaSaver = mediaSaver
    }
    
    @MainActor
    func saveMedia() async {
        isLoading = true
        
        var successMessage = ""
        if let imageUrl = portion.imageURL,
           let data = fileManager.getImage(for: imageUrl)?.jpegData(compressionQuality: 1) {
            do {
                try await mediaSaver.saveImageData(data)
                successMessage = "Saved."
            } catch MediaSaverError.noPermission {
                successMessage = "Couldn't save. No add photo permission."
            } catch {
                successMessage = "Save failed."
            }
        } else if let videoUrl = portion.videoURL {
            do {
                try await mediaSaver.saveVideo(by: videoUrl)
                successMessage = "Saved."
            } catch MediaSaverError.noPermission {
                successMessage = "Couldn't save. No add photo permission."
            } catch {
                successMessage = "Save failed."
            }
        }
        
        isLoading = false
        showNotice(message: successMessage)
    }
    
    private func showNotice(message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.noticeMsg = message
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.noticeMsg = ""
            }
        }
    }
    
    // *** In real environment, the photo or video should be deleted by API call,
    // this is a demo app, however, deleting them from temp directory.
    func deletePortionMedia() {
        guard let fileURL = portion.imageURL ?? portion.videoURL else { return }
        
        try? fileManager.delete(for: fileURL)
    }
    
    deinit {
        print("\(String(describing: Self.self)): \(portion.id) deinit.")
    }
}
