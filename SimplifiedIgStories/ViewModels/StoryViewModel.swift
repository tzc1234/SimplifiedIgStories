//
//  StoryViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/03/2022.
//

import Foundation
import SwiftUI

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
    
    let story: Story
    let storiesViewModel: StoriesViewModel
    
    init(story: Story, storiesViewModel: StoriesViewModel) {
        self.story = story
        self.storiesViewModel = storiesViewModel
        self.initCurrentStoryPortionId()
    }
}

// MARK: computed variables
extension StoryViewModel {
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
    
    func initAnimation(story: Story) {
        if storiesViewModel.currentStoryId == story.id && portionTransitionDirection == .none {
            print("StoryId: \(story.id) animation Init!!")
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
            guard let firstPortionId = story.portions.first?.id else { return }
            
            // At the first portion and
            if currentStoryPortionId == firstPortionId {
                // at the first story,
                if story.id == storiesViewModel.firstStoryIdDisplayedByContainer {
                    // just start the animation.
                    setCurrentBarPortionAnimationStatusTo(currentPortionAnimationStatus == .start ? .restart : .start)
                } else { // Not at the first story (that means previous story must exist.),
                    // go to previous story.
                    setCurrentBarPortionAnimationStatusTo(.inital)
                    
                    let atLeastOnePortionStories = storiesViewModel.atLeastOnePortionStories
                    guard let currentStoryIndex = atLeastOnePortionStories.firstIndex(where: { $0.id == story.id }) else {
                        return
                    }
                    
                    let previousStoryIndex = currentStoryIndex - 1
                    if previousStoryIndex >= 0 {
                        storiesViewModel.currentStoryId = atLeastOnePortionStories[previousStoryIndex].id
                    }
                }
            } else { // Not at the first story,
                // go back to previous portion normally.
                setCurrentBarPortionAnimationStatusTo(.inital)
                
                guard let currentStoryPortionIndex = story.portions.firstIndex(where: { $0.id == currentStoryPortionId }) else {
                    return
                }
                
                let previousStoryPortionIndex = currentStoryPortionIndex - 1
                if previousStoryPortionIndex >= 0 {
                    currentStoryPortionId = story.portions[previousStoryPortionIndex].id
                }
                
                setCurrentBarPortionAnimationStatusTo(.start)
            }
            
            portionTransitionDirection = .none // reset
        }
    }
    
    func performNextProgressBarPortionAnimationWhenFinished(_ portionAnimationStatus: BarPortionAnimationStatus?) {
        // Start next portion's animation when current bar portion finished.
        guard portionAnimationStatus == .finish else { return }
        
        guard let currentStoryPortionIndex = story.portions.firstIndex(where: { $0.id == currentStoryPortionId }) else {
            return
        }
        
        // At last portion now,
        if currentStoryPortionIndex + 1 > story.portions.count - 1 {
            let atLeastOnePortionStories = storiesViewModel.atLeastOnePortionStories
            guard let currentStoryIndex = atLeastOnePortionStories.firstIndex(where: { $0.id == storiesViewModel.currentStoryId }) else {
                return
            }
            
            // It's the last story now, close StoryContainer.
            if currentStoryIndex + 1 > atLeastOnePortionStories.count - 1 {
                storiesViewModel.closeStoryContainer()
            } else { // Not the last stroy now, go to next story.
                storiesViewModel.currentStoryId = atLeastOnePortionStories[currentStoryIndex + 1].id
            }
        } else { // Not the last portion, go to next portion.
            currentStoryPortionId = story.portions[currentStoryPortionIndex + 1].id
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
}
