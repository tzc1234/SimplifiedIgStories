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

enum BarPortionAnimationStatus {
    case inital, start, restart, pause, resume, finish
}

final class StoryViewModel: ObservableObject {
    typealias PortionId = Int
    
    @Published private(set) var currentStoryPortionId: PortionId = -1
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
        subscribePublishersForPauseResumePortion()
        
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
    var story: Story {
        // *** All the stories are from local JSON, not from API,
        // so I use force unwarp. Don't do this in real environment!
        storiesViewModel.stories.first(where: { $0.id == storyId })!
    }
    
    var currentPortionAnimationStatus: BarPortionAnimationStatus? {
        barPortionAnimationStatusDict[currentStoryPortionId]
    }
    
    var isCurrentPortionAnimating: Bool {
        currentPortionAnimationStatus == .start ||
        currentPortionAnimationStatus == .restart ||
        currentPortionAnimationStatus == .resume
    }
    
    var firstPortionId: PortionId? {
        story.portions.first?.id
    }
    
    private var currentStoryPortionIndex: Int? {
        story.portions.firstIndex(where: { $0.id == currentStoryPortionId })
    }
    
    private var currentStoryIndex: Int? {
        storiesViewModel.stories.firstIndex(where: { $0.id == storyId })
    }
    
    private var currentPortion: Portion? {
        story.portions.first(where: { $0.id == currentStoryPortionId })
    }
}

// MARK: private functions
extension StoryViewModel {
    private func initCurrentStoryPortionId() {
        guard let firstPortionId = firstPortionId else { return }
        currentStoryPortionId = firstPortionId
    }
    
    private func setCurrentBarPortionAnimationStatus(to status: BarPortionAnimationStatus) {
        barPortionAnimationStatusDict[currentStoryPortionId] = status
    }
    
    private func subscribePublishersForPauseResumePortion() {
        $showConfirmationDialog.combineLatest($showNoticeLabel).sink
        { [weak self] (isConfirmationDialogShown, isNoticeLabelShown) in
            if isConfirmationDialogShown || isNoticeLabelShown {
                self?.pausePortionAnimation()
            } else {
                self?.resumePortionAnimation()
            }
        }
        .store(in: &subscriptions)
    }
}

// MARK: functions for StoyView
extension StoryViewModel {
    func initStoryAnimation(by storyId: Int) {
        if storiesViewModel.currentStoryId == storyId && portionTransitionDirection == .none {
            print("StoryId: \(storyId) animation init!!")
            portionTransitionDirection = .start
        }
    }
    
    func decidePortionTransitionDirection(by pointX: CGFloat) {
        portionTransitionDirection = pointX <= .screenWidth / 2 ? .backward : .forward
    }
    
    func deleteCurrentPortion(withoutNextPortionAction: () -> Void) {
        guard let currentStoryPortionIndex = currentStoryPortionIndex else {
            return
        }
        
        let portions = story.portions

        // If next portion exists, go next.
        if currentStoryPortionIndex + 1 < portions.count {
            deletePortionFromStory(by: currentStoryPortionIndex)
            currentStoryPortionId = portions[currentStoryPortionIndex + 1].id
            setCurrentBarPortionAnimationStatus(to: .start)
        } else {
            withoutNextPortionAction()
            deletePortionFromStory(by: currentStoryPortionIndex)
        }
    }
    
    // *** In real environment, the photo or video should be deleted by API call,
    // this is a demo app, however, deleting them from temp directory.
    private func deletePortionFromStory(by portionIdx: Int) {
        guard let currentStoryIndex = currentStoryIndex else {
            return
        }
        
        let portion = story.portions[portionIdx]
        if let fileUrl = portion.imageUrl ?? portion.videoUrl {
            fileManager.deleteFileBy(url: fileUrl)
        }
        
        storiesViewModel.stories[currentStoryIndex].portions.remove(at: portionIdx)
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
    
    func getImage(by portionId: PortionId) -> Image? {
        let portion = story.portions.first(where: { $0.id == portionId })
        if let imageName = portion?.imageName {
            return Image(imageName)
        } else if let imageUrl = portion?.imageUrl,
                  let uiImage = LocalFileManager().getImageBy(url: imageUrl) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}

// MARK: functions for ProgressBar
extension StoryViewModel {
    func performProgressBarTransition(to transitionDirection: PortionTransitionDirection) {
        // Not in current story, ignore.
        guard storiesViewModel.currentStoryId == story.id else { return }
        
        switch transitionDirection {
        case .none: // For continue tap forward/backward to trigger onChange.
            break
        case .start:
            // No first portion, should not be happened.
            guard let firstPortionId = firstPortionId else { return }
            
            currentStoryPortionId = firstPortionId
            setCurrentBarPortionAnimationStatus(to: .start)
        case .forward:
            setCurrentBarPortionAnimationStatus(to: .finish)
            // Will trigger the onChange of currentPortionAnimationStatus in ProgressBar.
        case .backward:
            // No first portion, should not happen.
            guard let firstPortionId = firstPortionId else { return }
            
            // At the first portion and
            if currentStoryPortionId == firstPortionId {
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
                
                guard
                    let currentStoryPortionIdx =
                        story.portions.firstIndex(where: { $0.id == currentStoryPortionId })
                else {
                    return
                }
                
                let prevStoryPortionIdx = currentStoryPortionIdx - 1
                if prevStoryPortionIdx >= 0 {
                    currentStoryPortionId = story.portions[prevStoryPortionIdx].id
                }
                
                setCurrentBarPortionAnimationStatus(to: .start)
            }
            
            portionTransitionDirection = .none // reset
        }
    }
    
    func performNextProgressBarPortionAnimationWhenFinished(_ portionAnimationStatus: BarPortionAnimationStatus?) {
        // Start next portion's animation when current bar portion finished.
        guard portionAnimationStatus == .finish else { return }
        
        guard
            let currentStoryPortionIdx =
                story.portions.firstIndex(where: { $0.id == currentStoryPortionId })
        else {
            return
        }
        
        // At last portion now,
        if currentStoryPortionIdx + 1 > story.portions.count - 1 {
            let currentStories = storiesViewModel.currentStories
            guard
                let currentStoryIdx =
                    currentStories.firstIndex(where: { $0.id == storiesViewModel.currentStoryId })
            else {
                return
            }
            
            // It's the last story now, close StoryContainer.
            if currentStoryIdx + 1 > currentStories.count - 1 {
                // TODO:
//                storiesViewModel.closeStoryContainer()
            } else { // Not the last stroy now, go to next story.
                storiesViewModel.setCurrentStoryId(currentStories[currentStoryIdx + 1].id)
            }
        } else { // Not the last portion, go to next portion.
            currentStoryPortionId = story.portions[currentStoryPortionIdx + 1].id
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
