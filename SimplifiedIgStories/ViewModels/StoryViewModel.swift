//
//  StoryViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/03/2022.
//

import Combine
import UIKit

enum BarPortionAnimationStatus: CaseIterable {
    case initial, start, restart, pause, resume, finish
}

protocol ParentStoryViewModel {
    var objectWillChange: ObservableObjectPublisher { get }
    var stories: [Story] { get set }
    var firstCurrentStoryId: Int? { get }
    var currentStoryId: Int { get }
    var shouldCubicRotation: Bool { get }
    var isNowAtLastStory: Bool { get }
    var isSameStoryAfterDragging: Bool { get }
    
    func getIsDraggingPublisher() -> AnyPublisher<Bool, Never>
    func moveCurrentStory(to direction: StoryMoveDirection)
}

final class StoryViewModel: ObservableObject {
    enum PortionTransitionDirection {
        case forward, backward
    }
    
    @Published private(set) var currentPortionId = -1
    @Published private var portionTransitionDirection: PortionTransitionDirection = .forward
    @Published private(set) var barPortionAnimationStatusDict: [Int: BarPortionAnimationStatus] = [:]
    
    @Published var showConfirmationDialog = false
    @Published private(set) var isLoading = false
    @Published private(set) var showNoticeLabel = false
    @Published private(set) var noticeMsg = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    private let storyId: Int
    private var parentViewModel: ParentStoryViewModel
    private let fileManager: ImageFileManageable
    private let mediaSaver: MediaSaver
    
    init(storyId: Int,
         parentViewModel: ParentStoryViewModel,
         fileManager: ImageFileManageable,
         mediaSaver: MediaSaver) {
        self.storyId = storyId
        self.parentViewModel = parentViewModel
        self.fileManager = fileManager
        self.mediaSaver = mediaSaver
        
        initCurrentStoryPortionId()
        initBarPortionAnimationStatus()
        subscribeStoriesViewModelPublishers()
        subscribeSelfPublishers()
        
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
    var story: Story {
        parentViewModel.stories.first(where: { $0.id == storyId })!
    }
    
    private var portions: [Portion] {
        story.portions
    }
    
    var currentPortionAnimationStatus: BarPortionAnimationStatus? {
        barPortionAnimationStatusDict[currentPortionId]
    }
    
    private var isCurrentPortionAnimating: Bool {
        currentPortionAnimationStatus == .start ||
        currentPortionAnimationStatus == .restart ||
        currentPortionAnimationStatus == .resume
    }
    
    private var isAtFirstPortion: Bool {
        currentPortionId == firstPortionId
    }
    
    private var isAtLastPortion: Bool {
        currentPortionId == portions.last?.id
    }
    
    private var isAtFirstStory: Bool {
        storyId == parentViewModel.firstCurrentStoryId
    }
    
    private var firstPortionId: Int? {
        portions.first?.id
    }
    
    private var currentPortionIndex: Int? {
        portions.firstIndex(where: { $0.id == currentPortionId })
    }
    
    private var currentPortion: Portion? {
        portions.first(where: { $0.id == currentPortionId })
    }
    
    var currentStoryId: Int {
        parentViewModel.currentStoryId
    }
    
    private var isCurrentStory: Bool {
        currentStoryId == storyId
    }
    
    var shouldCubicRotation: Bool {
        parentViewModel.shouldCubicRotation
    }
}

// MARK: Helpers
extension StoryViewModel {
    private func initCurrentStoryPortionId() {
        guard let firstPortionId else { return }
        
        currentPortionId = firstPortionId
    }
    
    private func initBarPortionAnimationStatus() {
        setCurrentBarPortionAnimationStatus(to: .initial)
    }
    
    private func setCurrentBarPortionAnimationStatus(to status: BarPortionAnimationStatus) {
        barPortionAnimationStatusDict[currentPortionId] = status
    }
    
    private func subscribeStoriesViewModelPublishers() {
        parentViewModel
            .getIsDraggingPublisher()
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] dragging in
                self?.updateBarPortionAnimationStatusWhenDragging(dragging)
            }
            .store(in: &subscriptions)
    }
    
    private func subscribeSelfPublishers() {
        $showConfirmationDialog
            .combineLatest($showNoticeLabel)
            .sink { [weak self] (isConfirmationDialogShown, isNoticeLabelShown) in
                if isConfirmationDialogShown || isNoticeLabelShown {
                    self?.pausePortionAnimation()
                } else {
                    self?.resumePortionAnimation()
                }
            }
            .store(in: &subscriptions)
        
        $portionTransitionDirection
            .dropFirst()
            .sink { [weak self] transitionDirection in
                guard let self else { return }
                
                print("storyId: \(storyId) | transits to \(transitionDirection).")
                performProgressBarAnimation(to: transitionDirection)
            }
            .store(in: &subscriptions)
    }
}

// MARK: functions for StoryView
extension StoryViewModel {
    func setPortionTransitionDirection(by pointX: CGFloat) {
        portionTransitionDirection = pointX <= .screenWidth/2 ? .backward : .forward
    }
    
    func deleteCurrentPortion(whenNoNextPortion action: () -> Void) {
        guard let currentPortionIndex else { return }

        // If next portion exists, go next.
        if currentPortionIndex+1 < portions.count {
            deletePortionFromStory(for: currentPortionIndex)
            moveToNewCurrentPortion(for: currentPortionIndex)
        } else {
            action()
            deletePortionFromStory(for: currentPortionIndex)
        }
    }
    
    private func moveToNewCurrentPortion(for portionIndex: Int) {
        currentPortionId = portions[portionIndex].id
        setCurrentBarPortionAnimationStatus(to: .start)
    }
}

// MARK: functions for animations
extension StoryViewModel {
    func startProgressBarAnimation() {
        guard isCurrentStory && !isCurrentPortionAnimating else {
            return
        }
        
        setCurrentBarPortionAnimationStatus(to: .start)
    }
    
    func pausePortionAnimation() {
        if isCurrentStory && isCurrentPortionAnimating {
            setCurrentBarPortionAnimationStatus(to: .pause)
        }
    }
    
    func resumePortionAnimation() {
        if isCurrentStory && currentPortionAnimationStatus == .pause {
            setCurrentBarPortionAnimationStatus(to: .resume)
        }
    }
    
    func finishPortionAnimation(for portionId: Int) {
        barPortionAnimationStatusDict[portionId] = .finish
    }
    
    private func performProgressBarAnimation(to transitionDirection: PortionTransitionDirection) {
        switch transitionDirection {
        case .forward:
            // Will trigger the onChange of currentPortionAnimationStatus in ProgressBar.
            setCurrentBarPortionAnimationStatus(to: .finish)
        case .backward:
            if isAtFirstPortion {
                if isAtFirstStory {
                    // just start the animation.
                    setCurrentBarPortionAnimationStatus(to: currentPortionAnimationStatus == .start ? .restart : .start)
                } else { // Not at the first story (that means the previous story must exist.)
                    setCurrentBarPortionAnimationStatus(to: .initial)
                    // then go to previous story.
                    parentViewModel.moveCurrentStory(to: .previous)
                }
            } else { // Not at the first portion
                setCurrentBarPortionAnimationStatus(to: .initial)
                moveToPreviewPortion()
            }
        }
    }
    
    func performNextBarPortionAnimationWhenCurrentPortionFinished(whenNoNextStory action: () -> Void) {
        guard currentPortionAnimationStatus == .finish else { return }
        
        if isAtLastPortion {
            // It's the last story now, noNextStory action perform.
            if parentViewModel.isNowAtLastStory {
                action()
            } else { // Not the last story now, go to next story.
                parentViewModel.moveCurrentStory(to: .next)
            }
        } else { // Not the last portion, go to next portion.
            moveToNextPortion()
        }
    }
    
    private func moveToPreviewPortion() {
        guard let currentPortionIndex else { return }
        
        if currentPortionIndex-1 >= 0 {
            currentPortionId = portions[currentPortionIndex-1].id
            setCurrentBarPortionAnimationStatus(to: .start)
        }
    }
    
    private func moveToNextPortion() {
        guard let currentPortionIndex else { return }
        
        if currentPortionIndex+1 < portions.count {
            currentPortionId = portions[currentPortionIndex+1].id
            setCurrentBarPortionAnimationStatus(to: .start)
        }
    }
    
    private func updateBarPortionAnimationStatusWhenDragging(_ isDragging: Bool) {
        if isDragging {
            pausePortionAnimation()
        } else { // Dragged.
            if parentViewModel.isSameStoryAfterDragging {
                resumePortionAnimation()
            }
        }
    }
}

// MARK: File management
extension StoryViewModel {
    @MainActor 
    func savePortionImageVideo() async {
        guard let currentPortion else { return }
        
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
        guard let currentStoryIndex = parentViewModel.stories.firstIndex(where: { $0.id == storyId }) else {
            return
        }
        
        let portion = portions[portionIndex]
        if let fileUrl = portion.imageURL ?? portion.videoURL {
            try? fileManager.deleteImage(for: fileUrl)
        }
        
        parentViewModel.stories[currentStoryIndex].portions.remove(at: portionIndex)
    }
    
    func getImage(by url: URL) -> UIImage? {
        fileManager.getImage(for: url)
    }
}
