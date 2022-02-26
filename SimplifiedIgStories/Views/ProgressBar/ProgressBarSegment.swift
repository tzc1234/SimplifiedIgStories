//
//  ProgressBarSegment.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct ProgressBarSegment: View {
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject private var storyGlobal: StoryGlobalObject
    
    // For pause animation.
    @State private var isAnimationPaused = false
    
    // For animation purpose.
    @State private var endX = 0.0
    
    // ProgressBarSegment will frequently be recreate,
    // TracingEndX must be a @StateObject to keep it unchange.
    @StateObject private var tracingEndX = TracingEndX(currentEndX: 0.0)
    
    let duration = 3.0
    
    let segmentIndex: Int
    let storyIndex: Int
    @ObservedObject private var tracingSegmentAnimation: TracingSegmentAnimation
    
    init(segmentIndex: Int, storyIndex: Int, tracingSegmentAnimation: TracingSegmentAnimation) {
        self.segmentIndex = segmentIndex
        self.storyIndex = storyIndex
        self.tracingSegmentAnimation = tracingSegmentAnimation
    }
    
    var body: some View {
        GeometryReader { geo in
            TraceableRectangle(startX: 0, endX: endX, tracingEndX: tracingEndX)
                .fill(.white)
                .background(Color(.lightGray).opacity(0.5))
                .cornerRadius(6)
                .onChange(of: tracingEndX.currentEndX) { currentEndX in
                    if currentEndX >= geo.size.width { // Finished
                        endAnimation(maxWidth: geo.size.width)
                    }
                }
                .onChange(of: tracingSegmentAnimation.currentSegmentIndex) { currentSegmentIndex in
//                    print("currentSegmentIndex: \(currentSegmentIndex), index: \(index)")
                    let newIndex = currentSegmentIndex < 0 ? 0 : currentSegmentIndex
                    if segmentIndex == newIndex {
                        startAnimation(maxWidth: geo.size.width)
                    } else if segmentIndex < newIndex { // For Previous segments:
                        endAnimation(maxWidth: geo.size.width)
                    } else { // For following segents:
                        initializeAnimation()
                    }
                }
                // Pause animation when scenePhase inactive
                .onChange(of: scenePhase) { newPhase in
                    let newIndex = tracingSegmentAnimation.currentSegmentIndex < 0 ? 0 : tracingSegmentAnimation.currentSegmentIndex
                    if segmentIndex == newIndex {
                        if newPhase == .active && isAnimationPaused {
                            startAnimation(maxWidth: geo.size.width)
                            isAnimationPaused = false
                        } else if newPhase == .inactive && !isAnimationPaused {
                            pauseAnimation()
                            isAnimationPaused = true
                        }
                    }
                }
                .onChange(of: storyGlobal.currentStoryIndex) { currentStoryIndex in
                    if currentStoryIndex == storyIndex {
                        if isAnimationPaused {
                            startAnimation(maxWidth: geo.size.width)
                            isAnimationPaused = false
                        }
                    } else { // Not in displaying.
                        pauseAnimation()
                    }
                }
            
        }
    }
}

struct ProgressBarSegment_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarSegment(
            segmentIndex: 0,
            storyIndex: 0,
            tracingSegmentAnimation: TracingSegmentAnimation()
        )
    }
}

// MARK: functions
extension ProgressBarSegment {
    func initializeAnimation() {
//        print("initializeAnimation, index: \(index)")
        withAnimation(.linear(duration: 0)) {
            endX = 0
        }
    }
    
    func startAnimation(maxWidth: Double) {
//        print("startAnimation, index: \(index)")
        
        let duration: Double
        if isAnimationPaused {
            duration = self.duration * (1 - tracingEndX.currentEndX / maxWidth)
        } else if !tracingSegmentAnimation.isTransitionForward {
            endX = 0
            duration = self.duration
        } else {
            duration = self.duration
        }
        
        withAnimation(.linear(duration: duration)) {
            endX = maxWidth
        }
    }
    
    func pauseAnimation() {
//        print("pauseAnimation, index: \(index)")
        withAnimation(.linear(duration: 0)) {
            endX = tracingEndX.currentEndX
        }
    }
    
    func endAnimation(maxWidth: Double) {
//        print("endAnimation, index: \(index)")
        withAnimation(.linear(duration: 0)) {
            endX = maxWidth + 0.1 // trick to stop animation!
            tracingEndX.updateCurrentEndX(0)
            
            let newIndex = tracingSegmentAnimation.currentSegmentIndex < 0 ? 0 : tracingSegmentAnimation.currentSegmentIndex
            if segmentIndex == newIndex {
                tracingSegmentAnimation.currentSegmentIndex = segmentIndex + 1
            }
        }
    }
}
