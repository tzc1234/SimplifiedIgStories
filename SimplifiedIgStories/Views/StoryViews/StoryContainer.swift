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
        .offset(x: vm.getContainerOffset(by: .screenWidth))
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
                    vm.endDraggingStoryContainer(withOffset: value.translation.width / .screenWidth)
                }
        )
        .statusBar(hidden: true)
        
    }
}

struct StoryContainer_Previews: PreviewProvider {
    static var previews: some View {
        StoryContainer()
            .environmentObject(StoriesViewModel())
    }
}
