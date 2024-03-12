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

final class StoryViewModel: ObservableObject {
    typealias PortionId = Int
    
    enum PortionTransitionDirection {
        case forward, backward
    }
    
    enum PortionMoveDirection {
        case previous, next
    }
    
    @Published private(set) var currentPortionId: PortionId = -1
    @Published private(set) var portionTransitionDirection: PortionTransitionDirection = .forward
    
    @Published var barPortionAnimationStatusDict: [PortionId: BarPortionAnimationStatus] = [:]
    
    @Published var showConfirmationDialog = false
    @Published private(set) var isLoading = false
    @Published private(set) var showNoticeLabel = false
    @Published private(set) var noticeMsg = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    let storyId: Int
    private let storiesViewModel: StoriesViewModel
    private let fileManager: ImageFileManageable
    private let mediaSaver: _MediaSaver
    
    init(
        storyId: Int,
        storiesViewModel: StoriesViewModel,
        fileManager: ImageFileManageable,
        mediaSaver: _MediaSaver
    ) {
        self.storyId = storyId
        self.storiesViewModel = storiesViewModel
        self.fileManager = fileManager
        self.mediaSaver = mediaSaver
        
        initCurrentStoryPortionId()
        initBarPortionAnimationStatus()
        subscribeStoriesViewModelPublishers()
        subscribeSelfPublishers()
        
        // Reference: https://stackoverflow.com/a/58406402
        // Trigger current ViewModel objectWillChange when parent's published property changed.
        storiesViewModel.objectWillChange.sink { [weak self] in
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
        storiesViewModel.stories.first(where: { $0.id == storyId })!
    }
    
    var portions: [Portion] {
        story.portions
    }
    
    var currentPortionAnimationStatus: BarPortionAnimationStatus? {
        barPortionAnimationStatusDict[currentPortionId]
    }
    
    var isCurrentPortionAnimating: Bool {
        currentPortionAnimationStatus == .start ||
        currentPortionAnimationStatus == .restart ||
        currentPortionAnimationStatus == .resume
    }
    
    var firstPortionId: PortionId? {
        portions.first?.id
    }
    
    var lastPortionId: PortionId? {
        portions.last?.id
    }
    
    var currentPortionIndex: Int? {
        portions.firstIndex(where: { $0.id == currentPortionId })
    }
    
    var currentPortion: Portion? {
        portions.first(where: { $0.id == currentPortionId })
    }
    
    var currentStoryId: Int {
        storiesViewModel.currentStoryId
    }
    
    var isCurrentStory: Bool {
        currentStoryId == storyId
    }
    
    var shouldCubicRotation: Bool {
        storiesViewModel.shouldCubicRotation
    }
}

// MARK: helper functions
extension StoryViewModel {
    private func initCurrentStoryPortionId() {
        guard let firstPortionId = firstPortionId else { return }
        currentPortionId = firstPortionId
    }
    
    private func initBarPortionAnimationStatus() {
        setCurrentBarPortionAnimationStatus(to: .initial)
    }
    
    func setCurrentBarPortionAnimationStatus(to status: BarPortionAnimationStatus) {
        barPortionAnimationStatusDict[currentPortionId] = status
    }
    
    private func subscribeStoriesViewModelPublishers() {
        storiesViewModel.$isDragging
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] dragging in
                self?.updateBarPortionAnimationStatusWhenDrag(dragging)
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
                guard let self = self else { return }
                print("storyId:\(self.storyId) | transitionDirection: \(transitionDirection)")
                self.performProgressBarAnimation(by: transitionDirection)
            }
            .store(in: &subscriptions)
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
    
    private func moveCurrentPortion(to direction: PortionMoveDirection) {
        guard let currentPortionIndex = currentPortionIndex else {
            return
        }
        
        switch direction {
        case .previous:
            if currentPortionIndex - 1 >= 0 {
                currentPortionId = portions[currentPortionIndex - 1].id
            }
        case .next:
            if currentPortionIndex + 1 < portions.count {
                currentPortionId = portions[currentPortionIndex + 1].id
            }
        }
    }
}

// MARK: functions for StoyView
extension StoryViewModel {
    func initStoryAnimation() {
        if isCurrentStory && currentPortionAnimationStatus == .initial {
            setCurrentBarPortionAnimationStatus(to: .start)
        }
    }
    
    func setPortionTransitionDirection(by pointX: CGFloat) {
        portionTransitionDirection = pointX <= .screenWidth / 2 ? .backward : .forward
    }
    
    func deleteCurrentPortion(withoutNextPortionAction: () -> Void) {
        guard let currentPortionIndex = currentPortionIndex else {
            return
        }

        // If next portion exists, go next.
        if currentPortionIndex + 1 < portions.count {
            deletePortionFromStory(by: currentPortionIndex)
            currentPortionId = portions[currentPortionIndex + 1].id
            setCurrentBarPortionAnimationStatus(to: .start)
        } else {
            withoutNextPortionAction()
            deletePortionFromStory(by: currentPortionIndex)
        }
    }
    
}

// MARK: functions for animations
extension StoryViewModel {
    private func performProgressBarAnimation(by transitionDirection: PortionTransitionDirection) {
        switch transitionDirection {
        case .forward:
            setCurrentBarPortionAnimationStatus(to: .finish)
            // Will trigger the onChange of currentPortionAnimationStatus in ProgressBar.
        case .backward:
            // At the first portion and
            if currentPortionId == firstPortionId {
                // at the first story,
                if storyId == storiesViewModel.firstCurrentStoryId {
                    // just start the animation.
                    setCurrentBarPortionAnimationStatus(to: currentPortionAnimationStatus == .start ? .restart : .start)
                } else { // Not at the first story (that means previous story must exist.),
                    // set current portion animation status back to initial,
                    setCurrentBarPortionAnimationStatus(to: .initial)
                    // and then go to previous story.
                    storiesViewModel.moveCurrentStory(to: .previous)
                }
            } else { // Not at the first portion,
                // set current portion animation status to initial,
                setCurrentBarPortionAnimationStatus(to: .initial)
                // go back to previous portion normally,
                moveCurrentPortion(to: .previous)
                // and start the previous portion animation (is now the current portion).
                setCurrentBarPortionAnimationStatus(to: .start)
            }
        }
    }
    
    // Start next bar portion's animation when current bar portion finished.
    func performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: () -> Void) {
        guard currentPortionAnimationStatus == .finish else {
            return
        }
        
        // At last portion now.
        if currentPortionId == lastPortionId {
            // It's the last story now, withoutNextStoryAction perform.
            if storiesViewModel.isNowAtLastStory {
                withoutNextStoryAction()
            } else { // Not the last story now, go to next story.
                storiesViewModel.moveCurrentStory(to: .next)
            }
        } else { // Not the last portion, go to next portion.
            moveCurrentPortion(to: .next)
            setCurrentBarPortionAnimationStatus(to: .start)
        }
    }
    
    private func updateBarPortionAnimationStatusWhenDrag(_ isDragging: Bool) {
        if isDragging {
            pausePortionAnimation()
        } else { // Dragged.
            if storiesViewModel.isSameStoryAfterDragged {
                resumePortionAnimation()
            } else {
                if isCurrentStory {
                    setCurrentBarPortionAnimationStatus(to: .start)
                }
                
                if storiesViewModel.storyIdBeforeDragged == storyId {
                    setCurrentBarPortionAnimationStatus(to: .initial)
                }
            }
        }
    }
    
    func startProgressBarAnimation() {
        guard isCurrentStory && !isCurrentPortionAnimating else {
            return
        }
        setCurrentBarPortionAnimationStatus(to: .start)
    }
}

// MARK: File management
extension StoryViewModel {
    @MainActor func savePortionImageVideo() async {
        guard let currentPortion = currentPortion else {
            return
        }
        
        do {
            isLoading = true
            
            var successMsg: String?
            if let imageUrl = currentPortion.imageUrl, let uiImage = fileManager.getImage(for: imageUrl) {
                successMsg = try await mediaSaver.saveToAlbum(uiImage)
            } else if let videoUrl = currentPortion.videoUrlFromCam {
                successMsg = try await mediaSaver.saveToAlbum(videoUrl)
            }
            
            isLoading = false
            
            if let successMsg = successMsg {
                showNotice(errMsg: successMsg)
            }
        } catch {
            isLoading = false
            let errMsg = (error as? MediaSavingError)?.errMsg ?? error.localizedDescription
            showNotice(errMsg: errMsg)
        }
    }
    
    private func showNotice(errMsg: String) {
        noticeMsg = errMsg
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showNoticeLabel = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.showNoticeLabel = false
            }
        }
    }
    
    // *** In real environment, the photo or video should be deleted by API call,
    // this is a demo app, however, deleting them from temp directory.
    private func deletePortionFromStory(by portionIndex: Int) {
        guard
            let currentStoryIndex = storiesViewModel.stories.firstIndex(where: { $0.id == storyId })
        else {
            return
        }
        
        let portion = portions[portionIndex]
        if let fileUrl = portion.imageUrl ?? portion.videoUrl {
            fileManager.deleteFile(by: fileUrl)
        }
        
        storiesViewModel.stories[currentStoryIndex].portions.remove(at: portionIndex)
    }
    
    func getImage(by url: URL) -> UIImage? {
        fileManager.getImage(for: url)
    }
}
