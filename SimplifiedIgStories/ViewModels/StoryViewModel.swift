//
//  StoryViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/03/2022.
//

import SwiftUI
import Combine

enum PortionTransitionDirection {
    case forward, backward
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
    @Published private(set) var portionTransitionDirection: PortionTransitionDirection = .forward
    
    @Published var barPortionAnimationStatusDict: [PortionId: BarPortionAnimationStatus] = [:]
    
    @Published var showConfirmationDialog = false
    @Published private(set) var isLoading = false
    @Published private(set) var showNoticeLabel = false
    @Published private(set) var noticeMsg = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    let storyId: Int
    let storiesViewModel: StoriesViewModel
    let fileManager: FileManageable
    
    init(storyId: Int, storiesViewModel: StoriesViewModel, fileManager: FileManageable) {
        self.storyId = storyId
        self.storiesViewModel = storiesViewModel
        self.fileManager = fileManager
        
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
    
    var lastPortionId: PortionId? {
        portions.last?.id
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
    
    var currentStoryId: Int {
        storiesViewModel.currentStoryId
    }
}

// MARK: helper functions
extension StoryViewModel {
    private func initCurrentStoryPortionId() {
        guard let firstPortionId = firstPortionId else { return }
        currentPortionId = firstPortionId
    }
    
    private func initBarPortionAnimationStatus() {
        setCurrentBarPortionAnimationStatus(to: .inital)
    }
    
    func setCurrentBarPortionAnimationStatus(to status: BarPortionAnimationStatus) {
        barPortionAnimationStatusDict[currentPortionId] = status
    }
    
    private func subscribeStoriesViewModelPublishers() {
        storiesViewModel.$isDragging
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] isDragging in
                self?.updateBarPortionAnimationStatusWhenDrag(isDragging)
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
    func initStoryAnimation() {
        if currentStoryId == storyId && currentPortionAnimationStatus == .inital {
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
                    // set current portion animation status back to inital,
                    setCurrentBarPortionAnimationStatus(to: .inital)
                    // and then go to previous story.
                    storiesViewModel.moveCurrentStory(to: .previous)
                }
            } else { // Not at the first portion,
                // set current portion animation status to inital,
                setCurrentBarPortionAnimationStatus(to: .inital)
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
            } else { // Not the last stroy now, go to next story.
                storiesViewModel.moveCurrentStory(to: .next)
            }
        } else { // Not the last portion, go to next portion.
            moveCurrentPortion(to: .next)
            setCurrentBarPortionAnimationStatus(to: .start)
        }
    }
    
    private func updateBarPortionAnimationStatusWhenDrag(_ isDragging: Bool) {
        guard currentStoryId == storyId else { return }
            
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
        guard currentStoryId == storyId && !isCurrentPortionAnimating else {
            return
        }
        setCurrentBarPortionAnimationStatus(to: .start)
    }
    
    func pasuseOrResumeProgressBarAnimationDepends(on scenePhase: ScenePhase) {
        guard currentStoryId == storyId else { return }
        
        if scenePhase == .active && currentPortionAnimationStatus == .pause {
            setCurrentBarPortionAnimationStatus(to: .resume)
        } else if scenePhase == .inactive && isCurrentPortionAnimating {
            setCurrentBarPortionAnimationStatus(to: .pause)
        }
    }
}

// MARK: File manage
extension StoryViewModel {
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
        guard let currentStoryIndex = storyIndex else {
            return
        }
        
        let portion = portions[portionIndex]
        if let fileUrl = portion.imageUrl ?? portion.videoUrl {
            fileManager.deleteFileBy(url: fileUrl)
        }
        
        storiesViewModel.stories[currentStoryIndex].portions.remove(at: portionIndex)
    }
    
    func getImageBy(url: URL) -> UIImage? {
        fileManager.getImageBy(url: url)
    }
}
