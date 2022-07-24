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
                        vm: StoryViewModel(storyId: story.id, storiesViewModel: vm)
                    )
                    .opacity(story.id != vm.currentStoryId && !vm.shouldCubicRotation ? 0.0 : 1.0)
                    .frame(width: .screenWidth, height: geo.size.height)
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
                    endDraggingStoryContainer(withOffset: value.translation.width / .screenWidth)
                }
        )
        .statusBar(hidden: true)
        
    }
}

struct StoryContainer_Previews: PreviewProvider {
    static var previews: some View {
        StoryContainer(vm: StoriesViewModel(localFileManager: LocalFileManager()))
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
    
    private func endDraggingStoryContainer(withOffset offset: CGFloat) {
        // Imitate the close behaviour of IG story when dragging right in the first story,
        // or dragging left in the last story, close the container.
        if (vm.isNowAtFirstStory && offset > 0.2) || (vm.isNowAtLastStory && offset < -0.2) {
            homeUIActionHandler.closeStoryContainer()
        } else { // Go to previous or next.
            guard let currentStoryIndex = vm.currentStoryIndex else {
                return
            }
            
            let nextIdx = Int((CGFloat(currentStoryIndex) - offset).rounded())
            // Make sure within the boundary.
            vm.setCurrentStoryId(vm.currentStories[min(nextIdx, vm.stories.count - 1)].id)
        }
        
        vm.isDragging = false
    }
}
