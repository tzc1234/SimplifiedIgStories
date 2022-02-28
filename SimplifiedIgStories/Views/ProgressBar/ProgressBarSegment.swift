//
//  ProgressBarSegment.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

enum ProgressBarSegemntAnimationStatus {
    case inital, start, pause, resume, finish
}

struct ProgressBarSegment: View {
    // For animation purpose.
    @State private var endX = 0.0
    // ProgressBarSegment will frequently be recreate,
    // TracingEndX must be a @StateObject to keep it unchange.
    @StateObject private var tracingEndX = TracingEndX(currentEndX: 0.0)
    
    let duration = 5.0
    
    let segmentIndex: Int
    @Binding var segemntAnimationStatuses: [Int: ProgressBarSegemntAnimationStatus]
    let storyIndex: Int
    
    var currentStatus: ProgressBarSegemntAnimationStatus? {
        segemntAnimationStatuses[segmentIndex]
    }
    
    // TODO: rmove storyIndex
    init(segmentIndex: Int, segemntAnimationStatuses: Binding<[Int: ProgressBarSegemntAnimationStatus]>, storyIndex: Int) {
        self.segmentIndex = segmentIndex
        self._segemntAnimationStatuses = segemntAnimationStatuses
        self.storyIndex = storyIndex
    }
    
    var body: some View {
        GeometryReader { geo in
            TraceableRectangle(startX: 0.0, endX: endX, tracingEndX: tracingEndX)
                .fill(.white)
                .background(Color(.lightGray).opacity(0.5))
                .cornerRadius(6)
                .onChange(of: tracingEndX.currentEndX) { currentEndX in
                    // Finished
                    if currentEndX >= geo.size.width {
                        tracingEndX.updateCurrentEndX(0)
                        segemntAnimationStatuses[segmentIndex] = .finish
                    }
                }
                .onChange(of: segemntAnimationStatuses[segmentIndex]) { newValue in
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
            
        }
    }
}

struct ProgressBarSegment_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarSegment(
            segmentIndex: 0,
            segemntAnimationStatuses: .constant([:]),
            storyIndex: 0
        )
    }
}

// MARK: functions
extension ProgressBarSegment {
    func initializeAnimation() {
        print("storyIndex\(storyIndex), Segment\(segmentIndex) initial.")
        withAnimation(.linear(duration: 0.0)) {
            endX = 0.0
        }
    }
    
    func startAnimation(maxWidth: Double) {
        print("storyIndex\(storyIndex), Segment\(segmentIndex) start.")
        endX = 0.0
        withAnimation(.linear(duration: duration)) {
            endX = maxWidth
        }
    }
    
    func pauseAnimation() {
        print("storyIndex\(storyIndex), Segment\(segmentIndex) pause.")
        withAnimation(.linear(duration: 0.0)) {
            endX = tracingEndX.currentEndX
        }
    }
    
    func resumeAnimation(maxWidth: Double) {
        print("storyIndex\(storyIndex), Segment\(segmentIndex) resume.")
        withAnimation(.linear(duration: duration * (1 - tracingEndX.currentEndX / maxWidth))) {
            endX = maxWidth
        }
    }
    
    func finishAnimation(maxWidth: Double) {
        print("storyIndex\(storyIndex), Segment\(segmentIndex) finish.")
        withAnimation(.linear(duration: 0.0)) {
            endX = maxWidth + 0.1 // trick to finish animation!
        }
    }
}
