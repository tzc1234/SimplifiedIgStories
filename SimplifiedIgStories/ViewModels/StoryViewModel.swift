//
//  StoryViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/03/2022.
//

import UIKit
import Combine

final class StoryViewModel: ObservableObject {
    @Published var showConfirmationDialog = false
    @Published private(set) var noticeMsg = ""
    
    private var cancellable: AnyCancellable?
    
    let storyId: Int
    let isCurrentUser: Bool
    let portion: Portion
    private let fileManager: FileManageable
    private let mediaSaver: MediaSaver
    private let pauseAnimation: () -> Void
    private let resumeAnimation: () -> Void
    
    init(story: Story,
         portion: Portion,
         fileManager: FileManageable,
         mediaSaver: MediaSaver,
         pauseAnimation: @escaping () -> Void,
         resumeAnimation: @escaping () -> Void) {
        self.storyId = story.id
        self.isCurrentUser = story.user.isCurrentUser
        self.portion = portion
        self.fileManager = fileManager
        self.mediaSaver = mediaSaver
        self.pauseAnimation = pauseAnimation
        self.resumeAnimation = resumeAnimation
        self.subscribePublisher()
    }
    
    private func subscribePublisher() {
        cancellable = $showConfirmationDialog
            .combineLatest($noticeMsg)
            .map { $0 || !$1.isEmpty }
            .sink { [weak self] animationShouldPause in
                if animationShouldPause {
                    self?.pauseAnimation()
                } else {
                    self?.resumeAnimation()
                }
            }
    }
    
    @MainActor
    func saveMedia() async {
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
    
    deinit {
        print("\(String(describing: Self.self)): \(portion.id) deinit.")
    }
}
