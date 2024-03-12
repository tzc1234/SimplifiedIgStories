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
    
    @ObservedObject var vm: StoriesViewModel // Injected from HomeView
    
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: 0) {
                // *** A risk of memory leak if too many stories.
                ForEach(vm.currentStories) { story in
                    StoryView(
                        storyId: story.id,
                        vm: StoryViewModel(
                            storyId: story.id,
                            storiesViewModel: vm,
                            fileManager: LocalImageFileManager(),
                            mediaSaver: LocalMediaSaver()
                        )
                    )
                    .opacity(story.id != vm.currentStoryId && !vm.shouldCubicRotation ? 0.0 : 1.0)
                    .frame(width: .screenWidth, height: geo.size.height)
                    .preference(key: FramePreferenceKey.self, value: geo.frame(in: .global))
                    .onPreferenceChange(FramePreferenceKey.self) { preferenceFrame in
                        vm.shouldCubicRotation = preferenceFrame.width == .screenWidth
                    }
                }
            }
        }
        .frame(width: .screenWidth, alignment: .leading)
        .offset(x: getContainerOffset(by: .screenWidth))
        .offset(x: translation)
        .animation(.interactiveSpring(), value: vm.currentStoryId)
        .animation(.interactiveSpring(), value: translation)
        .gesture(
            DragGesture()
                .updating($translation) { value, state, transaction in
                    vm.isDragging = true
                    vm.updateStoryIdBeforeDragged()
                    state = value.translation.width
                }
                .onEnded { value in
                    endDraggingStoryContainerWith(offset: value.translation.width / .screenWidth)
                }
        )
        .statusBar(hidden: true)
        
    }
}

struct StoryContainer_Previews: PreviewProvider {
    static var previews: some View {
        let vm = StoriesViewModel(fileManager: LocalImageFileManager())
        StoryContainer(vm: vm)
            .environmentObject(HomeUIActionHandler())
            .task {
                await vm.fetchStories()
            }
    }
}

// MARK: helper functions
extension StoryContainer {
    private func getContainerOffset(by width: CGFloat) -> CGFloat {
        guard let index = vm.currentStoryIndex else {
            return 0.0
        }
        
        return -CGFloat(index) * width
    }
    
    private func endDraggingStoryContainerWith(offset: CGFloat) {
        // Imitate the close behaviour of IG story when dragging to right in the first story,
        // or dragging to left in the last story, close the container.
        let threshold: CGFloat = 0.2
        if vm.isNowAtFirstStory && offset > threshold {
            homeUIActionHandler.closeStoryContainer(storyId: vm.firstCurrentStoryId)
        } else if vm.isNowAtLastStory && offset < -threshold {
            homeUIActionHandler.closeStoryContainer(storyId: vm.lastCurrentStoryId)
        } else if abs(offset.rounded()) > 0 {
            vm.moveCurrentStory(to: offset >= 0 ? .previous : .next)
        }
        
        vm.isDragging = false
    }
}
