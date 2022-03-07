//
//  ProgressBarPortion.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

enum ProgressBarPortionAnimationStatus {
    case inital, start, restart, pause, resume, finish
}

struct ProgressBarPortion: View {
    @Environment(\.scenePhase) private var scenePhase
    
    // For animation purpose.
    @State private var endX = 0.0
    // ProgressBarPortion will frequently be recreate,
    // TracingEndX must be a @StateObject to keep it unchange.
    @StateObject private var tracingEndX = TracingEndX(currentEndX: 0.0)
    
    
    @State private var traceableRectangleId = 0
    @State private var isAnimationPaused = false
    
    let portionIndex: Int
    @Binding var portionAnimationStatuses: [Int: ProgressBarPortionAnimationStatus]
    let duration: Double
    let storyIndex: Int // This storyIndex is for debug msg.
    
    init(portionIndex: Int, portionAnimationStatuses: Binding<[Int: ProgressBarPortionAnimationStatus]>, duration: Double, storyIndex: Int) {
        self.portionIndex = portionIndex
        self._portionAnimationStatuses = portionAnimationStatuses
        self.duration = duration
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
                        portionAnimationStatuses[portionIndex] = .finish
                    }
                }
                .onChange(of: currentAnimationStatus) { newValue in
                    if let portionAnimationStatus = newValue {
                        switch portionAnimationStatus {
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

struct ProgressBarPortion_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarPortion(
            portionIndex: 0,
            portionAnimationStatuses: .constant([:]),
            duration: 5.0,
            storyIndex: 0
        )
    }
}

// MARK: computed varibles
extension ProgressBarPortion {
    var currentAnimationStatus: ProgressBarPortionAnimationStatus? {
        portionAnimationStatuses[portionIndex]
    }
    
    var isAnimating: Bool {
        currentAnimationStatus == .start ||
        currentAnimationStatus == .restart ||
        currentAnimationStatus == .resume
    }
}

// MARK: functions
extension ProgressBarPortion {
    func resetTraceableRectangle(toLength endX: Double = 0.0) {
        self.endX = endX
        traceableRectangleId = traceableRectangleId == 0 ? 1 : 0
    }
    
    func initializeAnimation() {
        print("storyIndex\(storyIndex), portion\(portionIndex) initial.")
        resetTraceableRectangle()
    }
    
    func startAnimation(maxWidth: Double) {
        print("storyIndex\(storyIndex), portion\(portionIndex) start.")
        resetTraceableRectangle()
        withAnimation(.linear(duration: duration)) {
            endX = maxWidth
        }
    }
    
    // TODO: combine restartAnimation and startAnimation
    func restartAnimation(maxWidth: Double) {
        print("storyIndex\(storyIndex), portion\(portionIndex) restart.")
        resetTraceableRectangle()
        withAnimation(.linear(duration: duration)) {
            endX = maxWidth
        }
    }
    
    func pauseAnimation() {
        print("storyIndex\(storyIndex), portion\(portionIndex) pause.")
        resetTraceableRectangle(toLength: tracingEndX.currentEndX)
    }
    
    func resumeAnimation(maxWidth: Double) {
        print("storyIndex\(storyIndex), portion\(portionIndex) resume.")
        withAnimation(.linear(duration: duration * (1 - tracingEndX.currentEndX / maxWidth))) {
            endX = maxWidth
        }
    }
    
    func finishAnimation(maxWidth: Double) {
        print("storyIndex\(storyIndex), portion\(portionIndex) finish.")
        resetTraceableRectangle(toLength: maxWidth)
    }
}
