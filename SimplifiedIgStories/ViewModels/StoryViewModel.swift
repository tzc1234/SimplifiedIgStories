//
//  StoryViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/03/2022.
//

import Combine
import UIKit

protocol ParentStoryViewModel {
    var objectWillChange: ObservableObjectPublisher { get }
    var stories: [Story] { get }
    var firstCurrentStoryId: Int? { get }
    var currentStoryId: Int { get }
    var shouldCubicRotation: Bool { get }
    var isAtLastStory: Bool { get }
    var isSameStoryAfterDragging: Bool { get }
    
    func getIsDraggingPublisher() -> AnyPublisher<Bool, Never>
    func moveToPreviousStory()
    func moveToNextStory()
    func deletePortion(byId portionId: Int)
}

final class StoryViewModel: ObservableObject {
    @Published var showConfirmationDialog = false
    @Published private(set) var isLoading = false
    @Published private(set) var showNoticeLabel = false
    @Published private(set) var noticeMsg = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    private let storyId: Int
    private let parentViewModel: ParentStoryViewModel
    private let fileManager: FileManageable
    private let mediaSaver: MediaSaver
    private let currentPortion: () -> Portion?
    private let currentPortionIndex: () -> Int?
    private let moveToNewCurrentPortion: (Int) -> Void
    
    init(storyId: Int,
         parentViewModel: ParentStoryViewModel,
         fileManager: FileManageable,
         mediaSaver: MediaSaver,
         currentPortion: @escaping () -> Portion?,
         currentPortionIndex: @escaping () -> Int?,
         moveToNewCurrentPortion: @escaping (Int) -> Void) {
        self.storyId = storyId
        self.parentViewModel = parentViewModel
        self.fileManager = fileManager
        self.mediaSaver = mediaSaver
        self.currentPortion = currentPortion
        self.currentPortionIndex = currentPortionIndex
        self.moveToNewCurrentPortion = moveToNewCurrentPortion
        
        // Reference: https://stackoverflow.com/a/58406402
        // Trigger current ViewModel objectWillChange when parent's published property changed.
        parentViewModel
            .objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)
    }
    
    deinit {
        print("StoryViewModel: \(storyId) deinit.")
    }
}

// MARK: computed variables
extension StoryViewModel {
    // *** All the stories are from local JSON, not from API,
    // so force unwrap here. Don't do this in real environment!
    private var story: Story {
        parentViewModel.stories.first(where: { $0.id == storyId })!
    }
    
    private var portions: [Portion] {
        story.portions
    }
}

// MARK: functions for StoryView
extension StoryViewModel {
    func deleteCurrentPortion(whenNoNextPortion action: () -> Void) {
        guard let currentPortionIndex = currentPortionIndex() else { return }

        // If next portion exists, go next.
        let portion = portions[currentPortionIndex]
        if currentPortionIndex+1 < portions.count {
            deletePortionFromStory(portion)
            moveToNewCurrentPortion(currentPortionIndex)
        } else {
            action()
            deletePortionFromStory(portion)
        }
    }
}

// MARK: File management
extension StoryViewModel {
    @MainActor 
    func savePortionImageVideo() async {
        guard let currentPortion = currentPortion() else { return }
        
        isLoading = true
        var successMessage: String?
        
        if let imageUrl = currentPortion.imageURL, 
            let data = fileManager.getImage(for: imageUrl)?.jpegData(compressionQuality: 1) {
            do {
                try await mediaSaver.saveImageData(data)
                successMessage = "Saved."
            } catch MediaSaverError.noPermission {
                successMessage = "Couldn't save. No add photo permission."
            } catch {
                successMessage = "Save failed."
            }
        } else if let videoUrl = currentPortion.videoURL {
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
    
    private func showNotice(message: String?) {
        guard let message else { return }
        
        noticeMsg = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showNoticeLabel = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.showNoticeLabel = false
            }
        }
    }
    
    // *** In real environment, the photo or video should be deleted by API call,
    // this is a demo app, however, deleting them from temp directory.
    private func deletePortionFromStory(_ portion: Portion) {
        if let fileUrl = portion.imageURL ?? portion.videoURL {
            try? fileManager.delete(for: fileUrl)
        }
        
        parentViewModel.deletePortion(byId: portion.id)
    }
    
    func getImage(by url: URL) -> UIImage? {
        fileManager.getImage(for: url)
    }
}
