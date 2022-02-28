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
    
    @State private var segemntAnimationStatuses: [Int: ProgressBarSegemntAnimationStatus] = [:]
    
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
            
            ForEach(0..<numOfSegments) { index in
                ProgressBarSegment(segmentIndex: index, segemntAnimationStatuses: $segemntAnimationStatuses, storyIndex: storyIndex)
                
                Spacer(minLength: 2)
            }
        }
        .padding(.horizontal, 10)
        .onChange(of: storyPortionTransitionDirection) { newValue in
            switch newValue {
            case .none: // For continue tap forward/backward to trigger onChange.
                break
            case .start:
                setCurrentSegemntAnimationStatusTo(.inital)
                currentStoryPortionIndex = 0
                setCurrentSegemntAnimationStatusTo(.start)
            case .forward:
                setCurrentSegemntAnimationStatusTo(.finish)
                // will trigger the onChange of currentSegemntAnimationStatus below.
            case .backward:
                setCurrentSegemntAnimationStatusTo(.inital)
                
                // At the first segment and
                if currentStoryPortionIndex == 0 {
                    // at the first story,
                    if storyIndex == 0 {
                        // just restart animation.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            setCurrentSegemntAnimationStatusTo(.start)
                            storyPortionTransitionDirection = .none
                        }
                    } else { // Not the first story,
                        // go to previous story.
                        storyGlobal.currentStoryIndex -= 1
                    }
                } else {
                    // Go back to previous segment normally.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        currentStoryPortionIndex -= 1
                        setCurrentSegemntAnimationStatusTo(.start)
                        storyPortionTransitionDirection = .none
                    }
                }
            }
        }
        .onChange(of: currentSegemntAnimationStatus) { newValue in
            // Start next segment's animation.
            if newValue == .finish {
                // At last segment now,
                if currentStoryPortionIndex + 1 > numOfSegments - 1 {
                    // close StoryContainer, if it's the last story now.
                    if storyGlobal.currentStoryIndex + 1 > storyCount - 1 {
                        storyGlobal.closeStoryContainer()
                    } else { // go to next story.
                        storyGlobal.currentStoryIndex += 1
                    }
                } else { // go to next segment.
                    currentStoryPortionIndex += 1
                    setCurrentSegemntAnimationStatusTo(.start)
                }
                
                storyPortionTransitionDirection = .none
            }
        }
        .onChange(of: storyGlobal.isDragging) { isDragging in
//            print("story: \(storyIndex), segemntAnimationStatuses: \(segemntAnimationStatuses)")
            if isCurrentStory {
                if isDragging {
                    if isCurrentSegmentAnimating {
                        setCurrentSegemntAnimationStatusTo(.pause)
                    }
                } else { // end dragged
                    if !isCurrentSegmentAnimating && !isSameStoryAfterDragged {
                        setCurrentSegemntAnimationStatusTo(.start)
                    } else if isCurrentSegmentIdling && isLastPortion && isSameStoryAfterDragged {
                        setCurrentSegemntAnimationStatusTo(.start)
                    } else if currentSegemntAnimationStatus == .pause {
                        setCurrentSegemntAnimationStatusTo(.resume)
                    }
                }
            }
        }
        .onChange(of: storyGlobal.currentStoryIndex) { _ in
            if isCurrentStory {
                // After go to next story, start its animation.
                if !isCurrentSegmentAnimating {
                    setCurrentSegemntAnimationStatusTo(.start)
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
    
    var portions: [Portion] {
        modelData.stories[storyIndex].portions
    }
    
    var numOfSegments: Int {
        portions.count
    }
    
    var isCurrentStory: Bool {
        storyGlobal.currentStoryIndex == storyIndex
    }
    
    var currentSegemntAnimationStatus: ProgressBarSegemntAnimationStatus? {
        segemntAnimationStatuses[currentStoryPortionIndex]
    }
    
    var isCurrentSegmentAnimating: Bool {
        currentSegemntAnimationStatus == .start || currentSegemntAnimationStatus == .resume
    }
    
    var isCurrentSegmentIdling: Bool {
        currentSegemntAnimationStatus == nil || currentSegemntAnimationStatus == .inital
    }
    
    var isSameStoryAfterDragged: Bool {
        storyGlobal.currentStoryIndex == storyGlobal.storyIndexBeforeDragged
    }
    
    var isLastPortion: Bool {
        currentStoryPortionIndex == numOfSegments - 1
    }
}

// MARK: functions
extension ProgressBar {
    func setCurrentSegemntAnimationStatusTo(_ status: ProgressBarSegemntAnimationStatus) {
        segemntAnimationStatuses[currentStoryPortionIndex] = status
    }
}
