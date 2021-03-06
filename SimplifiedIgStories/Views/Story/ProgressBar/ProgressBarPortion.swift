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
    // TracingEndX must be a @StateObject to keep it unchange.
    @StateObject private var tracingEndX = TracingEndX(currentEndX: 0.0)
    
    // For reset animation!
    @State private var traceableRectangleId = 0
    
    let portionId: Int
    let duration: Double
    let storyId: Int
    @ObservedObject private var vm: StoryViewModel
    
    init(portionId: Int, duration: Double, storyId: Int, storyViewModel: StoryViewModel) {
        self.portionId = portionId
        self.duration = duration
        self.storyId = storyId
        self.vm = storyViewModel
    }
    
    var body: some View {
        GeometryReader { geo in
            TraceableRectangle(startX: 0.0, endX: endX, tracingEndX: tracingEndX)
                .fill(.white)
                .background(Color(.lightGray).opacity(0.5))
                .cornerRadius(6)
                .id(traceableRectangleId)
                .onChange(of: tracingEndX.currentEndX) { currentEndX in
                    // Finished
                    if currentEndX >= geo.size.width {
                        tracingEndX.updateCurrentEndX(0)
                        vm.barPortionAnimationStatusDict[portionId] = .finish
                    }
                }
                .onChange(of: vm.barPortionAnimationStatusDict[portionId]) { newValue in
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
                            finishAnimation()
                        }
                    }
                }

        }
    }
}

struct ProgressBarPortion_Previews: PreviewProvider {
    static var previews: some View {
        let storiesViewModel = StoriesViewModel(fileManager: LocalFileManager())
        let story = storiesViewModel.stories[1]
        ProgressBarPortion(
            portionId: story.portions[0].id,
            duration: .defaultStoryDuration,
            storyId: story.id,
            storyViewModel: StoryViewModel(
                storyId: story.id,
                storiesViewModel: storiesViewModel,
                fileManager: LocalFileManager()
            )
        )
    }
}

// MARK: functions
extension ProgressBarPortion {
    private func resetTraceableRectangle(toLength endX: Double = 0.0) {
        self.endX = endX
        traceableRectangleId = traceableRectangleId == 0 ? 1 : 0
    }
    
    private func initializeAnimation() {
        print("storyId: \(storyId), portionId: \(portionId) initial.")
        resetTraceableRectangle()
    }
    
    private func startAnimation(maxWidth: Double) {
        print("storyId: \(storyId), portionId: \(portionId) start.")
        resetTraceableRectangle()
        withAnimation(.linear(duration: duration)) {
            endX = maxWidth
        }
    }
    
    // TODO: combine restartAnimation and startAnimation
    private func restartAnimation(maxWidth: Double) {
        print("storyId: \(storyId), portionId: \(portionId) restart.")
        resetTraceableRectangle()
        withAnimation(.linear(duration: duration)) {
            endX = maxWidth
        }
    }
    
    private func pauseAnimation() {
        print("storyId: \(storyId), portionId: \(portionId) pause.")
        resetTraceableRectangle(toLength: tracingEndX.currentEndX)
    }
    
    private func resumeAnimation(maxWidth: Double) {
        print("storyId: \(storyId), portionId: \(portionId) resume.")
        withAnimation(.linear(duration: duration * (1 - tracingEndX.currentEndX / maxWidth))) {
            endX = maxWidth
        }
    }
    
    private func finishAnimation() {
        print("storyId: \(storyId), portionId: \(portionId) finish.")
        resetTraceableRectangle(toLength: .screenWidth)
    }
}
