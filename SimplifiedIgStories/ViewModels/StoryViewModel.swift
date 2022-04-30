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
    @Published private(set) var currentStoryPortionId: Int = -1
    @Published private(set) var portionTransitionDirection: PortionTransitionDirection = .none
    
    // The key is portionId.
    @Published var barPortionAnimationStatuses: [Int: BarPortionAnimationStatus] = [:]
    
    @Published var showConfirmationDialog = false
    @Published private(set) var isLoading = false
    @Published private(set) var showNoticeLabel = false
    @Published private(set) var noticeMsg = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    let storyId: Int
    let storiesViewModel: StoriesViewModel // parent ViewModel
    
    init(storyId: Int, storiesViewModel: StoriesViewModel) {
        self.storyId = storyId
        self.storiesViewModel = storiesViewModel
        self.initCurrentStoryPortionId()
        
        // Reference: https://stackoverflow.com/a/58406402
        // Trigger current ViewModel objectWillChange when parent's published property changed.
        storiesViewModel.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
        .store(in: &subscriptions)
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
    private func initCurrentStoryPortionId() {
        guard let firstPortionId = firstPortionId else { return }
        currentStoryPortionId = firstPortionId
    }
    
    private func setCurrentBarPortionAnimationStatus(to status: BarPortionAnimationStatus) {
        barPortionAnimationStatuses[currentStoryPortionId] = status
    }
}

// MARK: functions for StoyView
extension StoryViewModel {
    func initStoryAnimation(by storyId: Int) {
        if storiesViewModel.currentStoryId == storyId && portionTransitionDirection == .none {
            print("StoryId: \(storyId) animation Init!!")
            portionTransitionDirection = .start
        }
    }
    
    func decidePortionTransitionDirection(by point: CGPoint) {
        portionTransitionDirection = point.x <= .screenWidth / 2 ? .backward : .forward
    }
    
    func deleteCurrentPortion() {
        guard
            let portionIdx =
                story.portions.firstIndex(where: { $0.id == currentStoryPortionId })
        else {
            return
        }
        
        let portions = story.portions

        // If next portionIdx within the portions, go next
        if portionIdx + 1 < portions.count {
            deletePortionFromStory(by: portionIdx)
            
            currentStoryPortionId = portions[portionIdx + 1].id
            setCurrentBarPortionAnimationStatus(to: .start)
        } else {
            storiesViewModel.closeStoryContainer()
            deletePortionFromStory(by: portionIdx)
        }
    }
    
    // *** In real environment, the photo or video should be deleted in server side,
    // this is a demo app, however, deleting them from temp directory.
    private func deletePortionFromStory(by portionIdx: Int) {
        guard
            let storyIdx =
                storiesViewModel.stories.firstIndex(where: { $0.id == storyId })
        else {
            return
        }
        
        let portion = story.portions[portionIdx]
        if let fileUrl = portion.imageUrl ?? portion.videoUrl {
            LocalFileManager.shared.deleteFileBy(url: fileUrl)
        }
        
        storiesViewModel.stories[storyIdx].portions.remove(at: portionIdx)
    }
    
    func savePortionImageVideo() {
        guard
            let portion =
                story.portions.first(where: { $0.id == currentStoryPortionId })
        else {
            return
        }
        
        var publisher: AnyPublisher<String, ImageVideoSaveError>?
        if let imageUrl = portion.imageUrl, let uiImage = LocalFileManager.shared.getImageBy(url: imageUrl) {
            isLoading = true
            publisher = ImageSaver().saveToAlbum(uiImage)
        } else if let videoUrl = portion.videoUrlFromCam {
            isLoading = true
            publisher = VideoSaver().saveToAlbum(videoUrl)
        }
        
        publisher?
             .receive(on: DispatchQueue.main)
             .sink { [weak self] completion in
                 self?.isLoading = false
                 
                 switch completion {
                 case .finished:
                     break
                 case .failure(let imageVideoError):
                     switch imageVideoError {
                     case .noAddPhotoPermission:
                         self?.showNotice(withMsg: "Couldn't save. No add photo permission.")
                     case .saveError(let err):
                         self?.showNotice(withMsg: "ERROR: \(err.localizedDescription)")
                     }
                 }
             } receiveValue: { [weak self] msg in
                 self?.showNotice(withMsg: msg)
             }
             .store(in: &subscriptions)
    }
    
    func showNotice(withMsg msg: String) {
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
                setCurrentBarPortionAnimationStatus(to: .pause)
            }
        } else {
            if currentPortionAnimationStatus == .pause {
                setCurrentBarPortionAnimationStatus(to: .resume)
            }
        }
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
                        storiesViewModel.currentStoryId = currentStories[prevStoryIdx].id
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
                storiesViewModel.closeStoryContainer()
            } else { // Not the last stroy now, go to next story.
                storiesViewModel.currentStoryId = currentStories[currentStoryIdx + 1].id
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
