//
//  ProgressBarSegment.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct ProgressBarSegment: View {
//    @Environment(\.scenePhase) var scenePhase
    
    // For animation purpose.
    @State private var endX = 0.0
    // ProgressBarSegment will frequently be recreate,
    // TracingEndX must be a @StateObject to keep it unchange.
    @StateObject private var tracingEndX = TracingEndX(currentEndX: 0.0)
    
    let duration = 3.0
    
    let segmentIndex: Int
    @ObservedObject private var segmentAnimationCoordinator: SegmentAnimationCoordinator
    
    init(segmentIndex: Int, segmentAnimationCoordinator: SegmentAnimationCoordinator) {
        self.segmentIndex = segmentIndex
        self.segmentAnimationCoordinator = segmentAnimationCoordinator
    }
    
    var body: some View {
        GeometryReader { geo in
            TraceableRectangle(startX: 0, endX: endX, tracingEndX: tracingEndX)
                .fill(.white)
                .background(Color(.lightGray).opacity(0.5))
                .cornerRadius(6)
                .onChange(of: tracingEndX.currentEndX) { currentEndX in
                    // Finished
                    if currentEndX >= geo.size.width {
                        tracingEndX.updateCurrentEndX(0)
                        segmentAnimationCoordinator.segemntAnimationStatuses[segmentIndex] = .finish
                    }
                }
                .onChange(of: segmentAnimationCoordinator.segemntAnimationStatuses[segmentIndex]) { newValue in
                    if let segemntAnimationStatus = newValue {
                        switch segemntAnimationStatus {
                        case .inital:
                            initializeAnimation()
                        case .start:
                            startAnimation(maxWidth: geo.size.width)
                        case .pause:
                            pauseAnimation()
                        case .resume:
                            resumeAnimation(maxWidth: geo.size.width)
                        case .finish:
                            finishAnimation(maxWidth: geo.size.width)
                        }
                    }
                }
            
//                .onChange(of: segmentAnimationCoordinator.currentSegmentIndex) { currentSegmentIndex in
//                    let newIndex = currentSegmentIndex < 0 ? 0 : currentSegmentIndex
//                    if segmentIndex == newIndex {
//                        playAnimation(maxWidth: geo.size.width)
//                    } else if segmentIndex < newIndex { // For Previous segments:
//                        finishAnimation(maxWidth: geo.size.width)
//                    } else { // For following segents:
//                        initializeAnimation()
//                    }
//                }
            
                // Pause animation when scenePhase inactive
//                .onChange(of: scenePhase) { newPhase in
//                    let newIndex = segmentAnimationCoordinator.currentSegmentIndex < 0 ? 0 : segmentAnimationCoordinator.currentSegmentIndex
//
//                    if segmentIndex == newIndex {
//                        if newPhase == .active && isAnimationPaused {
//                            playAnimation(maxWidth: geo.size.width)
//                            isAnimationPaused = false
//                        } else if newPhase == .inactive && !isAnimationPaused {
//                            pauseAnimation()
//                            isAnimationPaused = true
//                        }
//                    }
//                }
            
//                .onChange(of: storyGlobal.currentStoryIndex) { currentStoryIndex in
//                    if currentStoryIndex == storyIndex {
//                        if isAnimationPaused {
//                            playAnimation(maxWidth: geo.size.width)
//                            isAnimationPaused = false
//                        }
//                    } else { // Not in displaying.
//                        pauseAnimation()
//                    }
//                }
        }
    }
}

struct ProgressBarSegment_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarSegment(
            segmentIndex: 0,
            segmentAnimationCoordinator: SegmentAnimationCoordinator()
        )
    }
}

// MARK: functions
extension ProgressBarSegment {
    func initializeAnimation() {
        print("Segment\(segmentIndex) initial.")
        withAnimation(.linear(duration: 0)) {
            endX = 0
        }
    }
    
    func startAnimation(maxWidth: Double) {
        print("Segment\(segmentIndex) start.")
        endX = 0
        withAnimation(.linear(duration: duration)) {
            endX = maxWidth
        }
    }
    
    func pauseAnimation() {
        print("Segment\(segmentIndex) pause.")
        withAnimation(.linear(duration: 0)) {
            endX = tracingEndX.currentEndX
        }
    }
    
    func resumeAnimation(maxWidth: Double) {
        print("Segment\(segmentIndex) resume.")
        withAnimation(.linear(duration: duration * (1 - tracingEndX.currentEndX / maxWidth))) {
            endX = maxWidth
        }
    }
    
    func finishAnimation(maxWidth: Double) {
        print("Segment\(segmentIndex) finish.")
        withAnimation(.linear(duration: 0)) {
            endX = maxWidth + 0.1 // trick to finish animation!
            tracingEndX.updateCurrentEndX(0)
        }
    }
}
