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
    let story: Story
    @ObservedObject private var storyViewModel: StoryViewModel
    
    init(portionId: Int, duration: Double, story: Story, storyViewModel: StoryViewModel) {
        self.portionId = portionId
        self.duration = duration
        self.story = story
        self.storyViewModel = storyViewModel
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
                        storyViewModel.barPortionAnimationStatuses[portionId] = .finish
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

        }
    }
}

struct ProgressBarPortion_Previews: PreviewProvider {
    static var previews: some View {
        let storiesViewModel = StoriesViewModel(dataService: MockDataService())
        let story = storiesViewModel.stories[1]
        ProgressBarPortion(
            portionId: story.portions[0].id,
            duration: 5.0,
            story: story,
            storyViewModel: storiesViewModel.getStoryViewModelBy(story: story)
        )
    }
}

// MARK: computed varibles
extension ProgressBarPortion {
    var currentAnimationStatus: BarPortionAnimationStatus? {
        storyViewModel.barPortionAnimationStatuses[portionId]
    }
}

// MARK: functions
extension ProgressBarPortion {
    func resetTraceableRectangle(toLength endX: Double = 0.0) {
        self.endX = endX
        traceableRectangleId = traceableRectangleId == 0 ? 1 : 0
    }
    
    func initializeAnimation() {
        print("storyId: \(story.id), portionId: \(portionId) initial.")
        resetTraceableRectangle()
    }
    
    func startAnimation(maxWidth: Double) {
        print("storyId: \(story.id), portionId: \(portionId) start.")
        resetTraceableRectangle()
        withAnimation(.linear(duration: duration)) {
            endX = maxWidth
        }
    }
    
    // TODO: combine restartAnimation and startAnimation
    func restartAnimation(maxWidth: Double) {
        print("storyId: \(story.id), portionId: \(portionId) restart.")
        resetTraceableRectangle()
        withAnimation(.linear(duration: duration)) {
            endX = maxWidth
        }
    }
    
    func pauseAnimation() {
        print("storyId: \(story.id), portionId: \(portionId) pause.")
        resetTraceableRectangle(toLength: tracingEndX.currentEndX)
    }
    
    func resumeAnimation(maxWidth: Double) {
        print("storyId: \(story.id), portionId: \(portionId) resume.")
        withAnimation(.linear(duration: duration * (1 - tracingEndX.currentEndX / maxWidth))) {
            endX = maxWidth
        }
    }
    
    func finishAnimation(maxWidth: Double) {
        print("storyId: \(story.id), portionId: \(portionId) finish.")
        resetTraceableRectangle(toLength: maxWidth)
    }
}
