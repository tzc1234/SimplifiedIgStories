//
//  ProgressBar.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/2/2022.
//

import SwiftUI

/// The "BRAIN" of story animations.
struct ProgressBar: View {
    @EnvironmentObject private var modelData: ModelData
    @EnvironmentObject private var storyGlobal: StoryGlobalObject
    
    let storyIndex: Int
    @Binding private var storyPortionTransitionDirection: StoryPortionTransitionDirection
    @Binding private var currentStoryPortionIndex: Int
    
    @State private var portionAnimationStatuses: [Int: ProgressBarPortionAnimationStatus] = [:]
    
    init(
        storyIndex: Int,
        storyPortionTransitionDirection: Binding<StoryPortionTransitionDirection>,
        currentStoryPortionIndex: Binding<Int>)
    {
        self.storyIndex = storyIndex
        self._storyPortionTransitionDirection = storyPortionTransitionDirection
        self._currentStoryPortionIndex = currentStoryPortionIndex
    }
    
    var body: some View {
        HStack {
            Spacer(minLength: 2)
            
            ForEach(portions.indices) { index in
                ProgressBarPortion(
                    portionIndex: index,
                    portionAnimationStatuses: $portionAnimationStatuses,
                    duration: portions[index].duration,
                    storyIndex: storyIndex
                )
                
                Spacer(minLength: 2)
            }
        }
        .padding(.horizontal, 10)
        .onChange(of: storyPortionTransitionDirection) { newValue in
            switch newValue {
            case .none: // For continue tap forward/backward to trigger onChange.
                break
            case .start:
                setCurrentPortionAnimationStatusTo(.inital)
                currentStoryPortionIndex = 0
                setCurrentPortionAnimationStatusTo(.start)
            case .forward:
                setCurrentPortionAnimationStatusTo(.finish)
                // will trigger the onChange of currentPortionAnimationStatus below.
            case .backward:
                let previousStatus = currentPortionAnimationStatus
                
                // At the first portion and
                if currentStoryPortionIndex == 0 {
                    // at the first story,
                    if storyIndex == firstStoryIndex {
                        // just start animation.
                        setCurrentPortionAnimationStatusTo(previousStatus == .start ? .restart : .start)
                    } else { // Not the first story,
                        // go to previous story.
                        setCurrentPortionAnimationStatusTo(.inital)
                        storyGlobal.currentStoryIndex -= 1
                    }
                } else {
                    // Go back to previous portion normally.
                    setCurrentPortionAnimationStatusTo(.inital)
                    currentStoryPortionIndex -= 1
                    setCurrentPortionAnimationStatusTo(.start)
                }
                
                storyPortionTransitionDirection = .none // reset
            }
        }
        .onChange(of: currentPortionAnimationStatus) { newValue in
            // Start next portion's animation.
            if newValue == .finish {
                // At last portion now,
                if currentStoryPortionIndex + 1 > portionCount - 1 {
                    // close StoryContainer, if it's the last story now.
                    if storyGlobal.currentStoryIndex + 1 > storyCount - 1 {
                        storyGlobal.closeStoryContainer()
                    } else { // Not the last stroy, go to next story normally.
                        storyGlobal.currentStoryIndex += 1
                    }
                } else { // Not the last portion, go to next portion.
                    currentStoryPortionIndex += 1
                    setCurrentPortionAnimationStatusTo(.start)
                }
                
                storyPortionTransitionDirection = .none // reset
            }
        }
        .onChange(of: storyGlobal.isDragging) { isDragging in
            if isCurrentStory {
                if isDragging {
                    // Pause the animation when dragging.
                    if isCurrentPortionAnimating {
                        setCurrentPortionAnimationStatusTo(.pause)
                    }
                } else { // Dragged.
                    if !isCurrentPortionAnimating && !isSameStoryAfterDragged {
                        setCurrentPortionAnimationStatusTo(.start)
                    } else if currentPortionAnimationStatus == .pause {
                        setCurrentPortionAnimationStatusTo(.resume)
                    }
                }
            }
        }
        .onChange(of: storyGlobal.currentStoryIndex) { _ in
            if isCurrentStory {
                // After went to the next story, start its animation.
                if !isCurrentPortionAnimating {
                    setCurrentPortionAnimationStatusTo(.start)
                }
            }
        }
    }
    
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBar(
            storyIndex: 0,
            storyPortionTransitionDirection: .constant(.none),
            currentStoryPortionIndex: .constant(0)
        )
    }
}

// MARK: computed variables
extension ProgressBar {
    var storyCount: Int {
        modelData.stories.count
    }
    
    var firstStoryIndex: Int {
        modelData.firstStoryIndex
    }
    
    var portions: [Portion] {
        modelData.stories[storyIndex].portions
    }
    
    var portionCount: Int {
        portions.count
    }
    
    var isCurrentStory: Bool {
        storyGlobal.currentStoryIndex == storyIndex
    }
    
    var currentPortionAnimationStatus: ProgressBarPortionAnimationStatus? {
        portionAnimationStatuses[currentStoryPortionIndex]
    }
    
    var isCurrentPortionAnimating: Bool {
        currentPortionAnimationStatus == .start ||
        currentPortionAnimationStatus == .restart ||
        currentPortionAnimationStatus == .resume
    }
    
    var isSameStoryAfterDragged: Bool {
        storyGlobal.currentStoryIndex == storyGlobal.storyIndexBeforeDragged
    }
}

// MARK: functions
extension ProgressBar {
    func setCurrentPortionAnimationStatusTo(_ status: ProgressBarPortionAnimationStatus) {
        portionAnimationStatuses[currentStoryPortionIndex] = status
    }
}
