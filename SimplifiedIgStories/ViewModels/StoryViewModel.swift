//
//  StoryViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/03/2022.
//

import SwiftUI
import Combine

enum PortionTransitionDirection {
    case none, start, forward, backward
}

enum BarPortionAnimationStatus: CaseIterable {
    case inital, start, restart, pause, resume, finish
}

final class StoryViewModel: ObservableObject {
    typealias PortionId = Int
    
    enum PortionMoveDirection {
        case previous, next
    }
    
    @Published private(set) var currentPortionId: PortionId = -1
    @Published private(set) var portionTransitionDirection: PortionTransitionDirection = .none
    
    @Published var barPortionAnimationStatusDict: [PortionId: BarPortionAnimationStatus] = [:]
    
    @Published var showConfirmationDialog = false
    @Published private(set) var isLoading = false
    @Published private(set) var showNoticeLabel = false
    @Published private(set) var noticeMsg = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    let storyId: Int
    let storiesViewModel: StoriesViewModel // parent ViewModel
    let fileManager: FileManageable
    
    init(storyId: Int, storiesViewModel: StoriesViewModel, fileManager: FileManageable) {
        self.storyId = storyId
        self.storiesViewModel = storiesViewModel
        self.fileManager = fileManager
        
        initCurrentStoryPortionId()
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
    // so force unwarp here. Don't do this in real environment!
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
    
    var currentPortionIndex: Int? {
        portions.firstIndex(where: { $0.id == currentPortionId })
    }
    
    var storyIndex: Int? {
        storiesViewModel.stories.firstIndex(where: { $0.id == storyId })
    }
    
    var currentPortion: Portion? {
        portions.first(where: { $0.id == currentPortionId })
    }
}

// MARK: helper functions
extension StoryViewModel {
    private func initCurrentStoryPortionId() {
        guard let firstPortionId = firstPortionId else { return }
        currentPortionId = firstPortionId
    }
    
    func setCurrentBarPortionAnimationStatus(to status: BarPortionAnimationStatus) {
        barPortionAnimationStatusDict[currentPortionId] = status
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
            .removeDuplicates()
            .sink { [weak self] transitionDirection in
                guard let self = self else { return }
                print("storyId:\(self.storyId) | transitionDirection: \(transitionDirection)")
                self.performProgressBarTransition(to: transitionDirection)
            }
            .store(in: &subscriptions)
    }
    
    // *** In real environment, the photo or video should be deleted by API call,
    // this is a demo app, however, deleting them from temp directory.
    private func deletePortionFromStory(by portionIdx: Int) {
        guard let currentStoryIndex = storyIndex else {
            return
        }
        
        let portion = portions[portionIdx]
        if let fileUrl = portion.imageUrl ?? portion.videoUrl {
            fileManager.deleteFileBy(url: fileUrl)
        }
        
        storiesViewModel.stories[currentStoryIndex].portions.remove(at: portionIdx)
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
    
    private func pausePortionAnimation() {
        if isCurrentPortionAnimating {
            setCurrentBarPortionAnimationStatus(to: .pause)
        }
    }
    
    private func resumePortionAnimation() {
        if currentPortionAnimationStatus == .pause {
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
    func initStoryAnimation(by storyId: Int) {
        if storiesViewModel.currentStoryId == storyId && portionTransitionDirection == .none {
            portionTransitionDirection = .start
        }
    }
    
    func decidePortionTransitionDirection(by pointX: CGFloat) {
        portionTransitionDirection = pointX <= .screenWidth / 2 ? .backward : .forward
    }
    
    func deleteCurrentPortion(withoutNextPortionAction: () -> Void) {
        guard let currentStoryPortionIndex = currentPortionIndex else {
            return
        }

        // If next portion exists, go next.
        if currentStoryPortionIndex + 1 < portions.count {
            deletePortionFromStory(by: currentStoryPortionIndex)
            currentPortionId = portions[currentStoryPortionIndex + 1].id
            setCurrentBarPortionAnimationStatus(to: .start)
        } else {
            withoutNextPortionAction()
            deletePortionFromStory(by: currentStoryPortionIndex)
        }
    }
    
    @MainActor func savePortionImageVideo() async {
        guard let currentPortion = currentPortion else {
            return
        }
        
        do {
            isLoading = true
            
            var successMsg: String?
            if let imageUrl = currentPortion.imageUrl, let uiImage = fileManager.getImageBy(url: imageUrl) {
                successMsg = try await ImageSaver().saveToAlbum(uiImage)
            } else if let videoUrl = currentPortion.videoUrlFromCam {
                successMsg = try await VideoSaver().saveToAlbum(videoUrl)
            }
            
            isLoading = false
            
            if let successMsg = successMsg {
                showNotice(errMsg: successMsg)
            }
        } catch {
            isLoading = false
            let errMsg = (error as? ImageVideoSaveError)?.errMsg ?? error.localizedDescription
            showNotice(errMsg: errMsg)
        }
    }
    
    func getImage(by portionId: PortionId) -> Image? {
        let portion = portions.first(where: { $0.id == portionId })
        if let imageName = portion?.imageName {
            return Image(imageName)
        } else if let imageUrl = portion?.imageUrl,
                  let uiImage = fileManager.getImageBy(url: imageUrl) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}

// MARK: functions for ProgressBar
extension StoryViewModel {
    private func performProgressBarTransition(to transitionDirection: PortionTransitionDirection) {
        switch transitionDirection {
        case .none: // For continue tap forward/backward to trigger onChange.
            break
        case .start:
            // No first portion, should not be happened.
            guard let firstPortionId = firstPortionId else { return }
            
            currentPortionId = firstPortionId
            setCurrentBarPortionAnimationStatus(to: .start)
        case .forward:
            setCurrentBarPortionAnimationStatus(to: .finish)
            // Will trigger the onChange of currentPortionAnimationStatus in ProgressBar.
        case .backward:
            // No first portion, should not happen.
            guard let firstPortionId = firstPortionId else { return }
            
            // At the first portion and
            if currentPortionId == firstPortionId {
                // at the first story,
                if story.id == storiesViewModel.currentStories.first?.id {
                    // just start the animation.
                    setCurrentBarPortionAnimationStatus(to: currentPortionAnimationStatus == .start ? .restart : .start)
                } else { // Not at the first story (that means previous story must exist.),
                    // go to previous story.
                    setCurrentBarPortionAnimationStatus(to: .inital)
                    
                    let currentStories = storiesViewModel.currentStories
                    guard
                        let currentStoryIdx =
                            currentStories.firstIndex(where: { $0.id == story.id })
                    else {
                        return
                    }
                    
                    let prevStoryIdx = currentStoryIdx - 1
                    if prevStoryIdx >= 0 { // If within the boundary,
                        // go previous.
                        storiesViewModel.setCurrentStoryId(currentStories[prevStoryIdx].id)
                    }
                }
            } else { // Not at the first story,
                // go back to previous portion normally.
                setCurrentBarPortionAnimationStatus(to: .inital)
                
                guard let currentStoryPortionIdx = currentPortionIndex else {
                    return
                }
                
                let prevStoryPortionIdx = currentStoryPortionIdx - 1
                if prevStoryPortionIdx >= 0 {
                    currentPortionId = portions[prevStoryPortionIdx].id
                }
                
                setCurrentBarPortionAnimationStatus(to: .start)
            }
            
            portionTransitionDirection = .none // reset
        }
    }
    
    // Start next bar portion's animation when current bar portion finished.
    func performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: () -> Void) {
        guard currentPortionAnimationStatus == .finish else {
            return
        }
        
        guard let currentPortionIndex = currentPortionIndex else {
            return
        }
        
        // At last portion now.
        if currentPortionIndex >= portions.count - 1 {
            // It's the last story now, withoutNextStoryAction perform.
            if storiesViewModel.isNowAtLastStory {
                withoutNextStoryAction()
            } else { // Not the last stroy now, go to next story.
                storiesViewModel.moveCurrentStory(to: .next)
            }
        } else { // Not the last portion, go to next portion.
            moveCurrentPortion(to: .next)
            setCurrentBarPortionAnimationStatus(to: .start)
        }
        
        portionTransitionDirection = .none // reset
    }
    
    func performProgressBarTransitionWhen(isDragging: Bool) {
        guard storiesViewModel.currentStoryId == story.id else { return }
            
        if isDragging {
            // Pause the animation when dragging.
            if isCurrentPortionAnimating {
                setCurrentBarPortionAnimationStatus(to: .pause)
            }
        } else { // Dragged.
            if !isCurrentPortionAnimating && !storiesViewModel.isSameStoryAfterDragged {
                setCurrentBarPortionAnimationStatus(to: .start)
            } else if currentPortionAnimationStatus == .pause {
                setCurrentBarPortionAnimationStatus(to: .resume)
            }
        }
    }
    
    func startProgressBarAnimation() {
        guard storiesViewModel.currentStoryId == story.id else { return }
            
        // After went to the next story, start its animation.
        if !isCurrentPortionAnimating {
            setCurrentBarPortionAnimationStatus(to: .start)
        }
    }
    
    func pasuseOrResumeProgressBarAnimationDepends(on scenePhase: ScenePhase) {
        guard storiesViewModel.currentStoryId == story.id else { return }
        
        if scenePhase == .active && currentPortionAnimationStatus == .pause {
            setCurrentBarPortionAnimationStatus(to: .resume)
        } else if scenePhase == .inactive && isCurrentPortionAnimating {
            setCurrentBarPortionAnimationStatus(to: .pause)
        }
    }
}
