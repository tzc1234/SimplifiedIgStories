//
//  StoryViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/03/2022.
//

import Foundation
import SwiftUI
import Combine

enum PortionTransitionDirection {
    case none, start, forward, backward
}

enum BarPortionAnimationStatus {
    case inital, start, restart, pause, resume, finish
}

final class StoryViewModel: ObservableObject {
    @Published var currentStoryPortionId: Int = -1
    @Published var portionTransitionDirection: PortionTransitionDirection = .none
    
    // The key is portionId.
    @Published var barPortionAnimationStatuses: [Int: BarPortionAnimationStatus] = [:]
    
    @Published var showConfirmationDialog = false
    
    let barPortionAnimationStatusesPublisher =
    PassthroughSubject<[Int: BarPortionAnimationStatus], Never>()
    
    @Published var isLoading = false
    @Published var showNoticeLabel = false
    @Published var noticeMsg = ""
    
    let storyId: Int
    let storiesViewModel: StoriesViewModel // parent ViewModel
    private var anyCancellable: AnyCancellable?
    
    init(storyId: Int, storiesViewModel: StoriesViewModel) {
        self.storyId = storyId
        self.storiesViewModel = storiesViewModel
        self.initCurrentStoryPortionId()
        
        // Reference: https://stackoverflow.com/a/58406402
        // Trigger current ViewModel objectWillChange when parent's published property changed.
        anyCancellable = storiesViewModel.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
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
        barPortionAnimationStatuses[currentStoryPortionId]
    }
    
    var isCurrentPortionAnimating: Bool {
        currentPortionAnimationStatus == .start ||
        currentPortionAnimationStatus == .restart ||
        currentPortionAnimationStatus == .resume
    }
    
    var firstPortionId: Int? {
        story.portions.first?.id
    }
}

// MARK: functions
extension StoryViewModel {
    func initCurrentStoryPortionId() {
        guard let firstPortionId = firstPortionId else { return }
        currentStoryPortionId = firstPortionId
    }
    
    func initAnimation(storyId: Int) {
        if storiesViewModel.currentStoryId == storyId && portionTransitionDirection == .none {
            print("StoryId: \(storyId) animation Init!!")
            portionTransitionDirection = .start
        }
    }
    
    func decidePortionTransitionDirectionBy(point: CGPoint) {
        let screenWidth = UIScreen.main.bounds.width
        portionTransitionDirection = point.x <= screenWidth / 2 ? .backward : .forward
    }
    
    func setCurrentBarPortionAnimationStatusTo(_ status: BarPortionAnimationStatus) {
        barPortionAnimationStatuses[currentStoryPortionId] = status
    }
    
    func performProgressBarTransitionTo(_ transitionDirection: PortionTransitionDirection) {
        // Not in current story, ignore.
        guard storiesViewModel.currentStoryId == story.id else { return }
        
        switch transitionDirection {
        case .none: // For continue tap forward/backward to trigger onChange.
            break
        case .start:
            // No first portion, should not be happened.
            guard let firstPortionId = firstPortionId else { return }
            
            currentStoryPortionId = firstPortionId
            setCurrentBarPortionAnimationStatusTo(.start)
        case .forward:
            setCurrentBarPortionAnimationStatusTo(.finish)
            // Will trigger the onChange of currentPortionAnimationStatus in ProgressBar.
        case .backward:
            // No first portion, should not happen.
            guard let firstPortionId = firstPortionId else { return }
            
            // At the first portion and
            if currentStoryPortionId == firstPortionId {
                // at the first story,
                if story.id == storiesViewModel.currentStories.first?.id {
                    // just start the animation.
                    setCurrentBarPortionAnimationStatusTo(currentPortionAnimationStatus == .start ? .restart : .start)
                } else { // Not at the first story (that means previous story must exist.),
                    // go to previous story.
                    setCurrentBarPortionAnimationStatusTo(.inital)
                    
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
                        storiesViewModel.currentStoryId = currentStories[prevStoryIdx].id
                    }
                }
            } else { // Not at the first story,
                // go back to previous portion normally.
                setCurrentBarPortionAnimationStatusTo(.inital)
                
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
                
                setCurrentBarPortionAnimationStatusTo(.start)
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
                storiesViewModel.closeStoryContainer()
            } else { // Not the last stroy now, go to next story.
                storiesViewModel.currentStoryId = currentStories[currentStoryIdx + 1].id
            }
        } else { // Not the last portion, go to next portion.
            currentStoryPortionId = story.portions[currentStoryPortionIdx + 1].id
            setCurrentBarPortionAnimationStatusTo(.start)
        }
        
        portionTransitionDirection = .none // reset
    }
    
    func performProgressBarTransitionWhen(isDragging: Bool) {
        guard storiesViewModel.currentStoryId == story.id else { return }
            
        if isDragging {
            // Pause the animation when dragging.
            if isCurrentPortionAnimating {
                setCurrentBarPortionAnimationStatusTo(.pause)
            }
        } else { // Dragged.
            if !isCurrentPortionAnimating && !storiesViewModel.isSameStoryAfterDragged {
                setCurrentBarPortionAnimationStatusTo(.start)
            } else if currentPortionAnimationStatus == .pause {
                setCurrentBarPortionAnimationStatusTo(.resume)
            }
        }
    }
    
    func startProgressBarAnimation() {
        guard storiesViewModel.currentStoryId == story.id else { return }
            
        // After went to the next story, start its animation.
        if !isCurrentPortionAnimating {
            setCurrentBarPortionAnimationStatusTo(.start)
        }
    }
    
    func pasuseOrResumeProgressBarAnimationDependsOn(scenePhase: ScenePhase) {
        guard storiesViewModel.currentStoryId == story.id else { return }
        
        if scenePhase == .active && currentPortionAnimationStatus == .pause {
            setCurrentBarPortionAnimationStatusTo(.resume)
        } else if scenePhase == .inactive && isCurrentPortionAnimating {
            setCurrentBarPortionAnimationStatusTo(.pause)
        }
    }
    
    func deleteCurrentPortion() {
        // *** In real environment, the photo or video should be deleted in server side,
        // this is a demo app, however, deleting them from temp directory.
        guard
            let storyIdx =
                storiesViewModel.stories.firstIndex(where: { $0.id == storyId }),
            let portionIdx =
                story.portions.firstIndex(where: { $0.id == currentStoryPortionId })
        else {
            return
        }
        
        let portions = story.portions
        let portion = portions[portionIdx]
        
        if let fileUrl = portion.imageUrl ?? portion.videoUrl {
            LocalFileManager.instance.deleteFileBy(url: fileUrl)
        }
        
        storiesViewModel.stories[storyIdx].portions.remove(at: portionIdx)

        // If next portionIdx within the portions, go next
        if portionIdx + 1 < portions.count {
            currentStoryPortionId = portions[portionIdx + 1].id
            setCurrentBarPortionAnimationStatusTo(.start)
        } else {
            storiesViewModel.closeStoryContainer()
        }
    }
    
    func saveCurrentPortion() {
        guard
            let portion =
                story.portions.first(where: { $0.id == currentStoryPortionId })
        else {
            return
        }
        
        let completion: ImageVideoSaveCompletion = { result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(_):
                    self.isLoading = false
                    self.showNoticeMsg("Saved.")
                case .failure(let imageVideoSaveErr):
                    switch imageVideoSaveErr {
                    case .noAddPhotoPermission:
                        self.isLoading = false
                        self.showNoticeMsg("Couldn't save. No add photo permission.")
                    case .saveError(let err):
                        self.isLoading = false
                        self.showNoticeMsg("ERROR: \(err.localizedDescription)")
                    }
                }
            }
        }
        
        if let imageUrl = portion.imageUrl, let uiImage = LocalFileManager.instance.getImageBy(url: imageUrl) {
            let imageSaver = ImageSaver(completion: completion)
            isLoading = true
            imageSaver.saveImageToAlbum(uiImage)
        } else if let videoUrl = portion.videoUrlFromCam {
            let videoSaver = VideoSaver(completion: completion)
            isLoading = true
            videoSaver.saveVideoToAlbum(videoUrl)
        }
    }
    
    func showNoticeMsg(_ msg: String) {
        noticeMsg = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showNoticeLabel = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.showNoticeLabel = false
            }
        }
    }
    
    func pauseAndResumePortion(shouldPause: Bool) {
        if shouldPause {
            if isCurrentPortionAnimating {
                setCurrentBarPortionAnimationStatusTo(.pause)
            }
        } else {
            if currentPortionAnimationStatus == .pause {
                setCurrentBarPortionAnimationStatusTo(.resume)
            }
        }
    }
}
