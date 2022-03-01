//
//  ProgressBarSegment.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

enum ProgressBarSegemntAnimationStatus {
    case inital, start, restart, pause, resume, finish
}

struct ProgressBarSegment: View {
    @Environment(\.scenePhase) private var scenePhase
    
    // For animation purpose.
    @State private var endX = 0.0
    // ProgressBarSegment will frequently be recreate,
    // TracingEndX must be a @StateObject to keep it unchange.
    @StateObject private var tracingEndX = TracingEndX(currentEndX: 0.0)
    
    let duration = 5.0
    @State private var traceableRectangleId = 0
    @State private var isAnimationPaused = false
    
    let segmentIndex: Int
    @Binding var segemntAnimationStatuses: [Int: ProgressBarSegemntAnimationStatus]
    let storyIndex: Int // This storyIndex is for development / debug purpose.
    
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
                .id(traceableRectangleId) // For reset animation!
                .onChange(of: tracingEndX.currentEndX) { currentEndX in
                    // Finished
                    if currentEndX >= geo.size.width {
                        tracingEndX.updateCurrentEndX(0)
                        segemntAnimationStatuses[segmentIndex] = .finish
                    }
                }
                .onChange(of: currentAnimationStatus) { newValue in
                    if let segemntAnimationStatus = newValue {
                        switch segemntAnimationStatus {
                        case .inital:
                            initializeAnimation()
                        case .start:
                            startAnimation(maxWidth: geo.size.width)
                        case .restart:
                            restartAnimation(maxWidth: geo.size.width)
                        case .pause:
                            pauseAnimation()
                        case .resume:
                            resumeAnimation(maxWidth: geo.size.width)
                        case .finish:
                            finishAnimation(maxWidth: geo.size.width)
                        }
                    }
                }
                // Pause animation when inactive.
                .onChange(of: scenePhase) { newPhase in
                    if isAnimating {
                        if newPhase == .active && isAnimationPaused {
                            resumeAnimation(maxWidth: geo.size.width)
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
            segmentIndex: 0,
            segemntAnimationStatuses: .constant([:]),
            storyIndex: 0
        )
    }
}

// MARK: computed varibles
extension ProgressBarSegment {
    var currentAnimationStatus: ProgressBarSegemntAnimationStatus? {
        segemntAnimationStatuses[segmentIndex]
    }
    
    var isAnimating: Bool {
        currentAnimationStatus == .start ||
        currentAnimationStatus == .restart ||
        currentAnimationStatus == .resume
    }
}

// MARK: functions
extension ProgressBarSegment {
    func resetTraceableRectangle(toLength endX: Double = 0.0) {
        self.endX = endX
        traceableRectangleId = traceableRectangleId == 0 ? 1 : 0
    }
    
    func initializeAnimation() {
        print("storyIndex\(storyIndex), Segment\(segmentIndex) initial.")
        resetTraceableRectangle()
    }
    
    func startAnimation(maxWidth: Double) {
        print("storyIndex\(storyIndex), Segment\(segmentIndex) start.")
        resetTraceableRectangle()
        withAnimation(.linear(duration: duration)) {
            endX = maxWidth
        }
    }
    
    // TODO: combine restartAnimation and startAnimation
    func restartAnimation(maxWidth: Double) {
        print("storyIndex\(storyIndex), Segment\(segmentIndex) restart.")
        resetTraceableRectangle()
        withAnimation(.linear(duration: duration)) {
            endX = maxWidth
        }
    }
    
    func pauseAnimation() {
        print("storyIndex\(storyIndex), Segment\(segmentIndex) pause.")
        resetTraceableRectangle(toLength: tracingEndX.currentEndX)
    }
    
    func resumeAnimation(maxWidth: Double) {
        print("storyIndex\(storyIndex), Segment\(segmentIndex) resume.")
        withAnimation(.linear(duration: duration * (1 - tracingEndX.currentEndX / maxWidth))) {
            endX = maxWidth
        }
    }
    
    func finishAnimation(maxWidth: Double) {
        print("storyIndex\(storyIndex), Segment\(segmentIndex) finish.")
        resetTraceableRectangle(toLength: maxWidth)
    }
}
