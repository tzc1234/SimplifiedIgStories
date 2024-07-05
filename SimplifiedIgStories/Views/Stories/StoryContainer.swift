//
//  StoryContainer.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct StoryContainer: View {
    @EnvironmentObject private var homeUIActionHandler: HomeUIActionHandler
    @GestureState private var translation: CGFloat = 0
    @State private var shouldCubicRotation = false
    
    @ObservedObject var animationHandler: StoriesAnimationHandler
    
    let getStoryView: (StoryDTO) -> StoryView
    
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: 0) {
                // *** A risk of memory leak if too many stories.
                ForEach(animationHandler.currentStories) { story in
                    GeometryReader { innerGeo in
                        getStoryView(story)
                            .cubicTransition(
                                shouldRotate: shouldCubicRotation,
                                offsetX: innerGeo.frame(in: .global).minX
                            )
                    }
                    .opacity(story.id != animationHandler.currentStoryId && !shouldCubicRotation ? 0.0 : 1.0)
                    .frame(width: .screenWidth, height: geo.size.height)
                    .preference(key: FramePreferenceKey.self, value: geo.frame(in: .global))
                    .onPreferenceChange(FramePreferenceKey.self) { preferenceFrame in
                        shouldCubicRotation = preferenceFrame.width == .screenWidth
                    }
                }
            }
        }
        .frame(width: .screenWidth, alignment: .leading)
        .offset(x: getContainerOffset(by: .screenWidth))
        .offset(x: translation)
        .animation(.interactiveSpring(), value: animationHandler.currentStoryId)
        .animation(.interactiveSpring(), value: translation)
        .gesture(
            DragGesture()
                .onChanged { _ in
                    animationHandler.isDragging = true
                }
                .updating($translation) { value, state, _ in
                    animationHandler.saveStoryIdBeforeDragged()
                    state = value.translation.width
                }
                .onEnded { value in
                    endDraggingStoryContainerWith(offset: value.translation.width / .screenWidth)
                    animationHandler.isDragging = false
                }
        )
        .statusBar(hidden: true)
    }
}

// MARK: helper functions
extension StoryContainer {
    private func getContainerOffset(by width: CGFloat) -> CGFloat {
        guard let index = animationHandler.currentStoryIndex else {
            return 0.0
        }
        
        return -CGFloat(index) * width
    }
    
    private func endDraggingStoryContainerWith(offset: CGFloat) {
        // Imitate the close behaviour of IG story when dragging to right in the first story,
        // or dragging to left in the last story, close the container.
        let threshold: CGFloat = 0.2
        if animationHandler.isAtFirstStory && offset > threshold {
            homeUIActionHandler.closeStoryContainer(storyId: animationHandler.firstCurrentStoryId)
        } else if animationHandler.isAtLastStory && offset < -threshold {
            homeUIActionHandler.closeStoryContainer(storyId: animationHandler.lastCurrentStoryId)
        } else if abs(offset.rounded()) > 0 {
            offset >= 0 ? animationHandler.moveToPreviousStory() : animationHandler.moveToNextStory()
        }
    }
}

struct StoryContainer_Previews: PreviewProvider {
    static var previews: some View {
        StoryContainer(
            animationHandler: .preview,
            getStoryView: { _ in
                .preview
            })
            .environmentObject(HomeUIActionHandler())
    }
}
