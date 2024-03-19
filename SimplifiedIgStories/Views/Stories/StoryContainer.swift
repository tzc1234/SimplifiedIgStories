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
    
    @ObservedObject var storiesViewModel: StoriesViewModel // Injected from HomeView
    let getStoryView: (Story) -> StoryView
    
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: 0) {
                // *** A risk of memory leak if too many stories.
                ForEach(storiesViewModel.currentStories) { story in
                    getStoryView(story)
                        .opacity(story.id != storiesViewModel.currentStoryId && !storiesViewModel.shouldCubicRotation ? 0.0 : 1.0)
                        .frame(width: .screenWidth, height: geo.size.height)
                        .preference(key: FramePreferenceKey.self, value: geo.frame(in: .global))
                        .onPreferenceChange(FramePreferenceKey.self) { preferenceFrame in
                            storiesViewModel.shouldCubicRotation = preferenceFrame.width == .screenWidth
                        }
                }
            }
        }
        .frame(width: .screenWidth, alignment: .leading)
        .offset(x: getContainerOffset(by: .screenWidth))
        .offset(x: translation)
        .animation(.interactiveSpring(), value: storiesViewModel.currentStoryId)
        .animation(.interactiveSpring(), value: translation)
        .gesture(
            DragGesture()
                .onChanged { _ in
                    storiesViewModel.isDragging = true
                }
                .updating($translation) { value, state, _ in
                    storiesViewModel.saveStoryIdBeforeDragged()
                    state = value.translation.width
                }
                .onEnded { value in
                    endDraggingStoryContainerWith(offset: value.translation.width / .screenWidth)
                    storiesViewModel.isDragging = false
                }
        )
        .statusBar(hidden: true)
    }
}

// MARK: helper functions
extension StoryContainer {
    private func getContainerOffset(by width: CGFloat) -> CGFloat {
        guard let index = storiesViewModel.currentStoryIndex else {
            return 0.0
        }
        
        return -CGFloat(index) * width
    }
    
    private func endDraggingStoryContainerWith(offset: CGFloat) {
        // Imitate the close behaviour of IG story when dragging to right in the first story,
        // or dragging to left in the last story, close the container.
        let threshold: CGFloat = 0.2
        if storiesViewModel.isAtFirstStory && offset > threshold {
            homeUIActionHandler.closeStoryContainer(storyId: storiesViewModel.firstCurrentStoryId)
        } else if storiesViewModel.isAtLastStory && offset < -threshold {
            homeUIActionHandler.closeStoryContainer(storyId: storiesViewModel.lastCurrentStoryId)
        } else if abs(offset.rounded()) > 0 {
            offset >= 0 ? storiesViewModel.moveToPreviousStory() : storiesViewModel.moveToNextStory()
        }
    }
}

struct StoryContainer_Previews: PreviewProvider {
    static var previews: some View {
        let vm = StoriesViewModel.preview
        StoryContainer(
            storiesViewModel: vm,
            getStoryView: { story in
                .preview(storyId: story.id, parentViewModel: vm)
            })
            .environmentObject(HomeUIActionHandler())
            .task {
                await vm.fetchStories()
            }
    }
}
