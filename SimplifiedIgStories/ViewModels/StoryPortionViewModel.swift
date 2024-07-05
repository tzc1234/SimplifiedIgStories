//
//  StoryPortionViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/03/2022.
//

import Foundation

final class StoryPortionViewModel: ObservableObject {
    @Published var showConfirmationDialog = false
    @Published private(set) var isLoading = false
    @Published private(set) var noticeMessage = ""
    
    let storyId: Int
    let isCurrentUser: Bool
    let portion: PortionDTO
    private let fileManager: FileManageable
    private let mediaSaver: MediaSaver
    private let performAfterPointOneSecond: (@escaping () -> Void) -> Void
    private let performAfterOnePointFiveSecond: (@escaping () -> Void) -> Void
    
    init(story: StoryDTO,
         portion: PortionDTO,
         fileManager: FileManageable,
         mediaSaver: MediaSaver,
         performAfterPointOneSecond: @escaping (@escaping () -> Void) -> Void = { action in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { action() }
         },
         performAfterOnePointFiveSecond: @escaping (@escaping () -> Void) -> Void = { action in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { action() }
         }
    ) {
        self.storyId = story.id
        self.isCurrentUser = story.user.isCurrentUser
        self.portion = portion
        self.fileManager = fileManager
        self.mediaSaver = mediaSaver
        self.performAfterPointOneSecond = performAfterPointOneSecond
        self.performAfterOnePointFiveSecond = performAfterOnePointFiveSecond
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
        performAfterPointOneSecond { [weak self] in
            self?.noticeMessage = message
            self?.performAfterOnePointFiveSecond { [weak self] in
                self?.noticeMessage = ""
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
        print("\(String(describing: Self.self)) portionId: \(portion.id) deinit.")
    }
}
