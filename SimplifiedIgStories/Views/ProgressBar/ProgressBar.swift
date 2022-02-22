//
//  ProgressBar.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/2/2022.
//

import SwiftUI

final class TracingSegmentAnimation: ObservableObject {
    @Published var currentSegmentIndex = -1
    var isTransitionForward = true
}

struct ProgressBar: View {
    let numOfSegments: Int
    @Binding private var transitionDirectionFromParent: StoryView.AnimationTransitionDirection
    @Binding private var currentStoryPortionIndex: Int
    
    @StateObject private var tracingSegmentAnimation: TracingSegmentAnimation = TracingSegmentAnimation()
    
    init(
        numOfSegments: Int,
        transitionDirection: Binding<StoryView.AnimationTransitionDirection>,
        currentStoryPortionIndex: Binding<Int>
    ) {
        self.numOfSegments = numOfSegments
        self._transitionDirectionFromParent = transitionDirection
        self._currentStoryPortionIndex = currentStoryPortionIndex
    }
    
    var body: some View {
        HStack {
            Spacer(minLength: 2)
            
            ForEach(0..<numOfSegments) { index in
                ProgressBarSegment(index: index, tracingSegmentAnimation: tracingSegmentAnimation)
                Spacer(minLength: 2)
            }
        }
        .padding(.horizontal, 10)
        .onChange(of: transitionDirectionFromParent) { newValue in
            switch newValue {
            case .none:
                break
            case .forward:
                let nextIndex = tracingSegmentAnimation.currentSegmentIndex + 1
                tracingSegmentAnimation.currentSegmentIndex = nextIndex < 0 ? 1 : nextIndex
                tracingSegmentAnimation.isTransitionForward = true
                transitionDirectionFromParent = .none // reset
            case .backward:
                tracingSegmentAnimation.currentSegmentIndex -= 1
                tracingSegmentAnimation.isTransitionForward = false
                transitionDirectionFromParent = .none // reset
            }
        }
        .onChange(of: tracingSegmentAnimation.currentSegmentIndex) { newValue in
            if newValue < 0 {
                currentStoryPortionIndex = 0
            } else if newValue > numOfSegments - 1 {
                currentStoryPortionIndex = numOfSegments - 1
            } else {
                currentStoryPortionIndex = newValue
            }
        }
        
    }
    
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBar(numOfSegments: 10, transitionDirection: .constant(.forward), currentStoryPortionIndex: .constant(0))
    }
}
