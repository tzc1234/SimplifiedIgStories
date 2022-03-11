//
//  StoryContainer.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct StoryContainer: View {
    @EnvironmentObject private var vm: StoriesViewModel
    
    @GestureState private var translation: CGFloat = 0
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: 0) {
                // *** A risk of memory leak if too many stories.
                ForEach(vm.atLeastOnePortionStories) { story in
                    StoryView(story: story, storyViewModel: vm.getStoryViewModelBy(story: story))
                        .frame(width: screenWidth, height: geo.size.height)
                        .opacity(story.id != vm.currentStoryId && !vm.shouldAnimateCubicRotation ? 0.0 : 1.0)
                }
            }
        }
        .frame(width: screenWidth, alignment: .leading)
        .offset(x: vm.getContainerOffset(width: screenWidth))
        .offset(x: translation)
        .animation(.interactiveSpring(), value: vm.currentStoryId)
        .animation(.interactiveSpring(), value: translation)
        .gesture(
            DragGesture()
                .updating($translation) { value, state, transaction in
                    vm.dragStoryContainer()
                    state = value.translation.width
                }
                .onEnded { value in
                    vm.endDraggingStoryContainer(offset: value.translation.width / screenWidth)
                }
        )
        .statusBar(hidden: true)
        .onDisappear {
            // *** All storyViewModels are retained by the storiesViewModel,
            // remove all storyViewModels manually, deinit along with this storyContainer.
            vm.removeAllStoryViewModel()
        }
        
    }
}

struct StoryContainer_Previews: PreviewProvider {
    static var previews: some View {
        StoryContainer().environmentObject(StoriesViewModel())
    }
}
