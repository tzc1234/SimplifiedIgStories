//
//  ProgressBar.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/2/2022.
//

import SwiftUI

// TODO: remove, no need a observable object
final class SegmentAnimationCoordinator: ObservableObject {
    enum ProgressBarSegemntAnimationStatus {
        case inital, start, pause, resume, finish
    }
    @Published var segemntAnimationStatuses: [Int: ProgressBarSegemntAnimationStatus] = [:]
}

struct ProgressBar: View {
    @EnvironmentObject private var modelData: ModelData
    @EnvironmentObject private var storyGlobal: StoryGlobalObject
    
    let storyIndex: Int
    
    @Binding var storyPortionTransitionDirection: StoryPortionTransitionDirection
    @Binding private var currentSegmentIndex: Int
    
    @StateObject private var segmentAnimationCoordinator: SegmentAnimationCoordinator = SegmentAnimationCoordinator()
    
    var numOfSegments: Int {
        modelData.stories[storyGlobal.currentStoryIndex].portions.count
    }
    
    init(storyIndex: Int, storyPortionTransitionDirection: Binding<StoryPortionTransitionDirection>, currentSegmentIndex: Binding<Int>) {
        self.storyIndex = storyIndex
        self._storyPortionTransitionDirection = storyPortionTransitionDirection
        self._currentSegmentIndex = currentSegmentIndex
    }
    
    var body: some View {
        HStack {
            Spacer(minLength: 2)
            
            ForEach(0..<numOfSegments, id: \.self) { index in
                ProgressBarSegment(segmentIndex: index, segmentAnimationCoordinator: segmentAnimationCoordinator)
                Spacer(minLength: 2)
            }
        }
        .padding(.horizontal, 10)
        .onChange(of: storyPortionTransitionDirection) { newValue in
            switch newValue {
            case .none:
                break
            case .start:
                segmentAnimationCoordinator.segemntAnimationStatuses[currentSegmentIndex] = .inital
                currentSegmentIndex = 0
                
                segmentAnimationCoordinator.segemntAnimationStatuses[currentSegmentIndex] = .start
                storyPortionTransitionDirection = .none // reset
            case .forward:
                segmentAnimationCoordinator.segemntAnimationStatuses[currentSegmentIndex] = .finish
                
                currentSegmentIndex += 1
                if currentSegmentIndex > numOfSegments - 1 {
                    currentSegmentIndex = numOfSegments - 1
                    print("index excess.")
                } else {
                    segmentAnimationCoordinator.segemntAnimationStatuses[currentSegmentIndex] = .start
                }
                
                storyPortionTransitionDirection = .none // reset
            case .backward:
                segmentAnimationCoordinator.segemntAnimationStatuses[currentSegmentIndex] = .inital
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    currentSegmentIndex -= 1
                    if currentSegmentIndex < 0 {
                        currentSegmentIndex = 0
                    }
                    
                    segmentAnimationCoordinator.segemntAnimationStatuses[currentSegmentIndex] = .start
                    storyPortionTransitionDirection = .none // reset
                }
            }
        }
        .onChange(of: segmentAnimationCoordinator.segemntAnimationStatuses[currentSegmentIndex]) { newValue in
            if let segemntAnimationStatus = newValue, segemntAnimationStatus == .finish {
                currentSegmentIndex += 1
                if currentSegmentIndex > numOfSegments - 1 {
                    currentSegmentIndex = numOfSegments - 1
                    print("index excess.")
                } else {
                    segmentAnimationCoordinator.segemntAnimationStatuses[currentSegmentIndex] = .start
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
            currentSegmentIndex: .constant(0)
        )
    }
}
