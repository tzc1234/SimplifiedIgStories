//
//  StoryViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 08/03/2022.
//

import Foundation
import SwiftUI

final class StoryViewModel: ObservableObject {
    @Published var currentStoryPortionId: Int = -1
    @Published var portionTransitionDirection: PortionTransitionDirection = .none
    
    // The key is portionId.
    @Published var portionAnimationStatuses: [Int: ProgressBarPortionAnimationStatus] = [:]
    
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
    var currentPortionAnimationStatus: ProgressBarPortionAnimationStatus? {
        portionAnimationStatuses[currentStoryPortionId]
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
    
    func decideStoryPortionTransitionDirection(point: CGPoint) {
        let screenWidth = UIScreen.main.bounds.width
        portionTransitionDirection = point.x <= screenWidth / 2 ? .backward : .forward
    }
    
    func setCurrentPortionAnimationStatusTo(_ status: ProgressBarPortionAnimationStatus) {
        portionAnimationStatuses[currentStoryPortionId] = status
    }
    
    func performProgressBarTransition(transitionDirection: PortionTransitionDirection) {
        guard storiesViewModel.currentStoryId == story.id else { return }
        switch transitionDirection {
        case .none: // For continue tap forward/backward to trigger onChange.
            break
        case .start:
            // No first portion, should not be happened.
            guard let firstPortionId = firstPortionId else { return }
            
            setCurrentPortionAnimationStatusTo(.inital)
            currentStoryPortionId = firstPortionId
            setCurrentPortionAnimationStatusTo(.start)
        case .forward:
            setCurrentPortionAnimationStatusTo(.finish)
            // Will trigger the onChange of currentPortionAnimationStatus in ProgressBar.
        case .backward:
            // No first portion should not be happened.
            guard let firstPortionId = story.portions.first?.id else { return }
            
            let previousStatus = currentPortionAnimationStatus
            
            // At the first portion and
            if currentStoryPortionId == firstPortionId {
                // at the first story,
                if story.id == storiesViewModel.firstStoryIdDisplayedByContainer {
                    // just start animation.
                    setCurrentPortionAnimationStatusTo(previousStatus == .start ? .restart : .start)
                } else { // Not at the first story (that means previous story must exist.),
                    // go to previous story.
                    setCurrentPortionAnimationStatusTo(.inital)
                    if let currentStoryIndex = storiesViewModel.atLeastOnePortionStories.firstIndex(where: { $0.id == story.id }) {
                        let previousStoryIndex = currentStoryIndex - 1
                        if previousStoryIndex >= 0 {
                            storiesViewModel.currentStoryId = storiesViewModel.atLeastOnePortionStories[previousStoryIndex].id
                        }
                    }
                }
            } else {
                // Go back to previous portion normally.
                setCurrentPortionAnimationStatusTo(.inital)
                
                if let currentStoryPortionIndex = story.portions.firstIndex(where: { $0.id == currentStoryPortionId }) {
                    let previousStoryPortionIndex = currentStoryPortionIndex - 1
                    if previousStoryPortionIndex >= 0 {
                        currentStoryPortionId = story.portions[previousStoryPortionIndex].id
                    }
                }
                
                setCurrentPortionAnimationStatusTo(.start)
            }
            
            portionTransitionDirection = .none // reset
        }
    }
    
    func performNextProgressBarPortionAnimation(portionAnimationStatus: ProgressBarPortionAnimationStatus?) {
        // Start next portion's animation.
        if portionAnimationStatus == .finish {
            guard let currentStoryPortionIndex = story.portions.firstIndex(where: { $0.id == currentStoryPortionId }) else {
                return
            }
            
            // At last portion now,
            if currentStoryPortionIndex + 1 > story.portions.count - 1 {
                guard let currentStoryIndex = storiesViewModel.atLeastOnePortionStories.firstIndex(where: { $0.id == storiesViewModel.currentStoryId }) else {
                    return
                }
                
                // It's the last story now, close StoryContainer.
                if currentStoryIndex + 1 > storiesViewModel.atLeastOnePortionStories.count - 1 {
                    storiesViewModel.closeStoryContainer()
                } else { // Not the last stroy now, go to next story normally.
                    storiesViewModel.currentStoryId = storiesViewModel.atLeastOnePortionStories[currentStoryIndex + 1].id
                }
            } else { // Not the last portion, go to next portion.
                currentStoryPortionId = story.portions[currentStoryPortionIndex + 1].id
                setCurrentPortionAnimationStatusTo(.start)
            }
            
            portionTransitionDirection = .none // reset
        }
    }
    
    func performProgressBarTransitionWhen(isDragging: Bool) {
        if storiesViewModel.currentStoryId == story.id {
            if isDragging {
                // Pause the animation when dragging.
                if isCurrentPortionAnimating {
                    setCurrentPortionAnimationStatusTo(.pause)
                }
            } else { // Dragged.
                if !isCurrentPortionAnimating && !storiesViewModel.isSameStoryAfterDragged {
                    setCurrentPortionAnimationStatusTo(.start)
                } else if currentPortionAnimationStatus == .pause {
                    setCurrentPortionAnimationStatusTo(.resume)
                }
            }
        }
    }
    
    func startProgressBarAnimation() {
        if storiesViewModel.currentStoryId == story.id {
            print("startProgressBarAnimation 0000")
            // After went to the next story, start its animation.
            if !isCurrentPortionAnimating {
                print("startProgressBarAnimation 1111")
                setCurrentPortionAnimationStatusTo(.start)
            }
        }
    }
}
