//
//  ProgressBar.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/2/2022.
//

import SwiftUI

/// The "BRAIN" of story animations.
struct ProgressBar: View {
    @EnvironmentObject private var vm: StoryViewModel
    
    let story: Story
    @Binding private var storyPortionTransitionDirection: StoryPortionTransitionDirection
    @Binding private var currentStoryPortionIndex: Int
    
    @State private var portionAnimationStatuses: [Int: ProgressBarPortionAnimationStatus] = [:]
    
    init(
        story: Story,
        storyPortionTransitionDirection: Binding<StoryPortionTransitionDirection>,
        currentStoryPortionIndex: Binding<Int>)
    {
        self.story = story
        self._storyPortionTransitionDirection = storyPortionTransitionDirection
        self._currentStoryPortionIndex = currentStoryPortionIndex
    }
    
    var body: some View {
        HStack {
            Spacer(minLength: 2)
            
            ForEach(story.portions.indices) { index in // TODO: potential bug.
                ProgressBarPortion(
                    portionIndex: index,
                    portionAnimationStatuses: $portionAnimationStatuses,
                    duration: story.portions[index].duration,
                    storyId: story.id
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
                    if story.id == vm.firstStoryIdDisplayedByContainer {
                        // just start animation.
                        setCurrentPortionAnimationStatusTo(previousStatus == .start ? .restart : .start)
                    } else { // Not the first story,
                        // go to previous story.
                        setCurrentPortionAnimationStatusTo(.inital)
                        vm.currentStoryId -= 1
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
                if currentStoryPortionIndex + 1 > story.portions.count - 1 {
                    // close StoryContainer, if it's the last story now.
                    if vm.currentStoryId + 1 > vm.stories.count - 1 {
                        vm.closeStoryContainer()
                    } else { // Not the last stroy, go to next story normally.
                        vm.currentStoryId += 1
                    }
                } else { // Not the last portion, go to next portion.
                    currentStoryPortionIndex += 1
                    setCurrentPortionAnimationStatusTo(.start)
                }
                
                storyPortionTransitionDirection = .none // reset
            }
        }
        .onChange(of: vm.isDragging) { isDragging in
            if isCurrentStory {
                if isDragging {
                    // Pause the animation when dragging.
                    if isCurrentPortionAnimating {
                        setCurrentPortionAnimationStatusTo(.pause)
                    }
                } else { // Dragged.
                    if !isCurrentPortionAnimating && !vm.isSameStoryAfterDragged {
                        setCurrentPortionAnimationStatusTo(.start)
                    } else if currentPortionAnimationStatus == .pause {
                        setCurrentPortionAnimationStatusTo(.resume)
                    }
                }
            }
        }
        .onChange(of: vm.currentStoryId) { _ in
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
        let vm = StoryViewModel(dataService: MockDataService())
        ProgressBar(
            story: vm.stories[1],
            storyPortionTransitionDirection: .constant(.none),
            currentStoryPortionIndex: .constant(0)
        )
            .environmentObject(StoryViewModel(dataService: MockDataService()))
    }
}

// MARK: computed variables
extension ProgressBar {
    var isCurrentStory: Bool {
        vm.currentStoryId == story.id
    }
    
    var currentPortionAnimationStatus: ProgressBarPortionAnimationStatus? {
        portionAnimationStatuses[currentStoryPortionIndex]
    }
    
    var isCurrentPortionAnimating: Bool {
        currentPortionAnimationStatus == .start ||
        currentPortionAnimationStatus == .restart ||
        currentPortionAnimationStatus == .resume
    }
}

// MARK: functions
extension ProgressBar {
    func setCurrentPortionAnimationStatusTo(_ status: ProgressBarPortionAnimationStatus) {
        portionAnimationStatuses[currentStoryPortionIndex] = status
    }
}
