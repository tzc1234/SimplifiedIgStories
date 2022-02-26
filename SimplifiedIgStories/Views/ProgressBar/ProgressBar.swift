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
    @EnvironmentObject private var modelData: ModelData
    @EnvironmentObject private var storyGlobal: StoryGlobalObject
    
    let storyIndex: Int
    
    @Binding var storyPortionTransitionDirection: StoryPortionTransitionDirection
    @Binding var currentStoryPortionIndex: Int
    @StateObject private var tracingSegmentAnimation: TracingSegmentAnimation = TracingSegmentAnimation()
    
    var numOfSegments: Int {
        modelData.stories[storyGlobal.currentStoryIndex].portions.count
    }
    
    init(storyIndex: Int, storyPortionTransitionDirection: Binding<StoryPortionTransitionDirection>, currentStoryPortionIndex: Binding<Int>) {
        self.storyIndex = storyIndex
        self._storyPortionTransitionDirection = storyPortionTransitionDirection
        self._currentStoryPortionIndex = currentStoryPortionIndex
    }
    
    var body: some View {
        HStack {
            Spacer(minLength: 2)
            
            ForEach(0..<numOfSegments, id: \.self) { index in
                ProgressBarSegment(segmentIndex: index, storyIndex: storyIndex, tracingSegmentAnimation: tracingSegmentAnimation)
                Spacer(minLength: 2)
            }
        }
        .padding(.horizontal, 10)
        .onChange(of: storyPortionTransitionDirection) { newValue in
            switch newValue {
            case .none:
                break
            case .forward:
                tracingSegmentAnimation.currentSegmentIndex = max(tracingSegmentAnimation.currentSegmentIndex + 1 , 0)
                tracingSegmentAnimation.isTransitionForward = true
                storyPortionTransitionDirection = .none // reset
            case .backward:
                tracingSegmentAnimation.currentSegmentIndex -= 1
                tracingSegmentAnimation.isTransitionForward = false
                storyPortionTransitionDirection = .none // reset
            }
        }
        .onChange(of: tracingSegmentAnimation.currentSegmentIndex) { newValue in
            // The usage of telling the StoryVIew to show which portion.
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
        ProgressBar(
            storyIndex: 0,
            storyPortionTransitionDirection: .constant(.none),
            currentStoryPortionIndex: .constant(0)
        )
    }
}
