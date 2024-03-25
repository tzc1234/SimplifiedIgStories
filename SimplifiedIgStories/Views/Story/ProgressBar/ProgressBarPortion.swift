//
//  ProgressBarPortion.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct ProgressBarPortion: View {
    // For animation purpose.
    @State private var endX = 0.0
    
    // ProgressBarPortion will frequently be recreate,
    // TracingEndX must be a @StateObject to keep the reference.
    @StateObject private var tracingEndX = TracingEndX(currentEndX: 0.0)
    
    // For reset animation!
    @State private var traceableRectangleId = 0
    
    private var storyId: Int {
        animationHandler.storyId
    }
    
    let portionIndex: Int
    let duration: Double
    @ObservedObject var animationHandler: StoryAnimationHandler
    
    var body: some View {
        GeometryReader { geo in
            TraceableRectangle(startX: 0.0, endX: endX, tracingEndX: tracingEndX)
                .fill(.white)
                .background(Color(.lightGray).opacity(0.5))
                .cornerRadius(6)
                .id(traceableRectangleId)
                .onChange(of: tracingEndX.currentEndX) { currentEndX in
                    if currentEndX >= geo.size.width { // Animation finished
                        animationHandler.finishPortionAnimation(at: portionIndex)
                    }
                }
                .onChange(of: animationHandler.portionAnimationStatusDict[portionIndex]) { status in
                    switch status {
                    case .initial:
                        initializeAnimation()
                    case .start, .restart:
                        startAnimation(maxWidth: geo.size.width)
                    case .pause:
                        pauseAnimation()
                    case .resume:
                        resumeAnimation(maxWidth: geo.size.width)
                    case .finish:
                        finishAnimation()
                    case .none:
                        break
                    }
                }
        }
    }
}

extension ProgressBarPortion {
    private func initializeAnimation() {
        print("storyId: \(storyId), portionIndex: \(portionIndex) initial.")
        resetTraceableRectangle()
    }
    
    private func startAnimation(maxWidth: Double) {
        print("storyId: \(storyId), portionIndex: \(portionIndex) start.")
        resetTraceableRectangle()
        withAnimation(.linear(duration: duration)) {
            endX = maxWidth
        }
    }
    
    private func pauseAnimation() {
        print("storyId: \(storyId), portionIndex: \(portionIndex) pause.")
        resetTraceableRectangle(toLength: tracingEndX.currentEndX)
    }
    
    private func resumeAnimation(maxWidth: Double) {
        print("storyId: \(storyId), portionIndex: \(portionIndex) resume.")
        withAnimation(.linear(duration: duration * (1-tracingEndX.currentEndX / maxWidth))) {
            endX = maxWidth
        }
    }
    
    private func finishAnimation() {
        print("storyId: \(storyId), portionIndex: \(portionIndex) finish.")
        resetTraceableRectangle(toLength: .screenWidth)
    }
    
    private func resetTraceableRectangle(toLength endX: Double = 0.0) {
        self.endX = endX
        traceableRectangleId = traceableRectangleId == 0 ? 1 : 0
    }
}

struct ProgressBarPortion_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarPortion(
            portionIndex: 0,
            duration: .defaultStoryDuration,
            animationHandler: .preview
        )
    }
}
