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
    private var animationHandler: StoryAnimationHandler?
    
    init(storyId: Int,
         parentViewModel: ParentStoryViewModel,
         fileManager: FileManageable,
         mediaSaver: MediaSaver) {
        self.storyId = storyId
        self.parentViewModel = parentViewModel
        self.fileManager = fileManager
        self.mediaSaver = mediaSaver
        
        // Reference: https://stackoverflow.com/a/58406402
        // Trigger current ViewModel objectWillChange when parent's published property changed.
        parentViewModel
            .objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)
        
        let animationHandler = StoryAnimationHandler(
            isAtFirstStory: { storyId == parentViewModel.firstCurrentStoryId },
            isAtLastStory: { parentViewModel.isAtLastStory },
            isCurrentStory: { parentViewModel.currentStoryId == storyId }, 
            moveToPreviousStory: parentViewModel.moveToPreviousStory,
            moveToNextStory: parentViewModel.moveToNextStory,
            portions: { [weak self] in self?.portions ?? [] },
            isSameStoryAfterDragging: { parentViewModel.isSameStoryAfterDragging },
            isDraggingPublisher: parentViewModel.getIsDraggingPublisher,
            animationShouldPausePublisher: $showConfirmationDialog
                .combineLatest($showNoticeLabel)
                .map { $0 || $1 }
                .eraseToAnyPublisher
        )
        
        self.animationHandler = animationHandler
        
        animationHandler
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
    
    var barPortionAnimationStatusDict: [Int: BarPortionAnimationStatus] {
        animationHandler?.barPortionAnimationStatusDict ?? [:]
    }
    
    var currentPortionAnimationStatus: BarPortionAnimationStatus? {
        animationHandler?.currentPortionAnimationStatus
    }
    
    var currentPortionId: Int? {
        animationHandler?.currentPortionId
    }
}

// MARK: functions for StoryView
extension StoryViewModel {
    func setPortionTransitionDirection(by pointX: CGFloat) {
        animationHandler?.setPortionTransitionDirection(by: pointX)
    }
    
    func deleteCurrentPortion(whenNoNextPortion action: () -> Void) {
        guard let currentPortionIndex = animationHandler?.currentPortionIndex else { return }

        // If next portion exists, go next.
        if currentPortionIndex+1 < portions.count {
            deletePortionFromStory(for: currentPortionIndex)
            animationHandler?.moveToNewCurrentPortion(for: currentPortionIndex)
        } else {
            action()
            deletePortionFromStory(for: currentPortionIndex)
        }
    }
}

// MARK: functions for animations
extension StoryViewModel {
    func startProgressBarAnimation() {
        animationHandler?.startProgressBarAnimation()
    }
    
    func pausePortionAnimation() {
        animationHandler?.pausePortionAnimation()
    }
    
    func resumePortionAnimation() {
        animationHandler?.resumePortionAnimation()
    }
    
    func finishPortionAnimation(for portionId: Int) {
        animationHandler?.finishPortionAnimation(for: portionId)
    }
    
    func performNextBarPortionAnimationWhenCurrentPortionFinished(whenNoNextStory action: () -> Void) {
        animationHandler?.performNextBarPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: action)
    }
}

// MARK: File management
extension StoryViewModel {
    @MainActor 
    func savePortionImageVideo() async {
        guard let currentPortion = animationHandler?.currentPortion else { return }
        
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
    private func deletePortionFromStory(for portionIndex: Int) {
        let portion = portions[portionIndex]
        if let fileUrl = portion.imageURL ?? portion.videoURL {
            try? fileManager.delete(for: fileUrl)
        }
        
        parentViewModel.deletePortion(byId: portion.id)
    }
    
    func getImage(by url: URL) -> UIImage? {
        fileManager.getImage(for: url)
    }
}
