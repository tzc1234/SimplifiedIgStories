//
//  ProgressBarSegment.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct ProgressBarSegment: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var isAnimationPaused = false
    
    // For animation purpose.
    @State private var endX = 0.0
    
    // ProgressBarSegment will frequently be recreate,
    // TracingEndX must be a @StateObject to keep it unchange.
    @StateObject private var tracingEndX = TracingEndX(currentEndX: 0.0)
    
    let duration = 3.0
    
    let index: Int
    @ObservedObject private var tracingSegmentAnimation: TracingSegmentAnimation
    
    init(index: Int, tracingSegmentAnimation: TracingSegmentAnimation) {
        self.index = index
        self.tracingSegmentAnimation = tracingSegmentAnimation
    }
    
    var body: some View {
        GeometryReader { geo in
            TraceableRectangle(startX: 0, endX: endX, tracingEndX: tracingEndX)
                .fill(.white)
                .background(Color(.lightGray).opacity(0.5))
                .cornerRadius(6)
                .onChange(of: tracingEndX.currentEndX) { currentEndX in
                    // Finish
                    if currentEndX >= geo.size.width {
                        endAnimation(maxWidth: geo.size.width)
                    }
                }
                .onChange(of: tracingSegmentAnimation.currentSegmentIndex) { currentSegmentIndex in
                    print("currentSegmentIndex: \(currentSegmentIndex), index: \(index)")
                    
                    let newIndex = currentSegmentIndex < 0 ? 0 : currentSegmentIndex
                    if index == newIndex {
                        startAnimation(maxWidth: geo.size.width)
                    } else if index < newIndex { // For Previous segments:
                        endAnimation(maxWidth: geo.size.width)
                    } else { // For following segents:
                        initializeAnimation()
                    }
                }
                // Pause animation when scenePhase inactive
                .onChange(of: scenePhase) { newPhase in
                    let newIndex = tracingSegmentAnimation.currentSegmentIndex < 0 ? 0 : tracingSegmentAnimation.currentSegmentIndex
                    if index == newIndex {
                        if newPhase == .active && isAnimationPaused {
                            startAnimation(maxWidth: geo.size.width)
                            isAnimationPaused = false
                        } else if newPhase == .inactive && !isAnimationPaused {
                            pauseAnimation()
                            isAnimationPaused = true
                        }
                    }
                }
            
        }
    }
}

struct ProgressBarSegment_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarSegment(
            index: 0,
            tracingSegmentAnimation: TracingSegmentAnimation()
        )
    }
}

// MARK: functions
extension ProgressBarSegment {
    func initializeAnimation() {
        print("initializeAnimation, index: \(index)")
        withAnimation(.linear(duration: 0)) {
            endX = 0
        }
    }
    
    func startAnimation(maxWidth: Double) {
        print("startAnimation, index: \(index)")
        
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
        print("pauseAnimation, index: \(index)")
        withAnimation(.linear(duration: 0)) {
            endX = tracingEndX.currentEndX
        }
    }
    
    func endAnimation(maxWidth: Double) {
        print("endAnimation, index: \(index)")
        withAnimation(.linear(duration: 0)) {
            endX = maxWidth + 0.1 // trick to stop animation!
            tracingEndX.updateCurrentEndX(0)
            
            let newIndex = tracingSegmentAnimation.currentSegmentIndex < 0 ? 0 : tracingSegmentAnimation.currentSegmentIndex
            if index == newIndex {
                tracingSegmentAnimation.currentSegmentIndex = index + 1
            }
        }
    }
}
