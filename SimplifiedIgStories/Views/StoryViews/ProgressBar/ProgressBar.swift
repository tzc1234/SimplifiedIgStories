//
//  ProgressBar.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/2/2022.
//

import SwiftUI

struct ProgressBar: View {
    @Environment(\.scenePhase) private var scenePhase
    
    let storyId: Int
    @ObservedObject private var vm: StoryViewModel
    
    init(storyId: Int, storyViewModel: StoryViewModel) {
        self.storyId = storyId
        self.vm = storyViewModel
    }
    
    var body: some View {
        HStack {
            Spacer(minLength: 2)
            
            ForEach(vm.story.portions) { portion in
                ProgressBarPortion(
                    portionId: portion.id,
                    duration: portion.duration,
                    storyId: storyId,
                    storyViewModel: vm
                )
                
                Spacer(minLength: 2)
            }
        }
        .padding(.horizontal, 10)
        .onChange(of: vm.portionTransitionDirection) { newDirection in
            vm.performProgressBarTransitionTo(newDirection)
        }
        .onChange(of: vm.currentPortionAnimationStatus) { newStatus in
            vm.performNextProgressBarPortionAnimationWhenFinished(newStatus)
        }
        .onChange(of: vm.storiesViewModel.isDragging) { isDragging in
            vm.performProgressBarTransitionWhen(isDragging: isDragging)
        }
        .onChange(of: vm.storiesViewModel.currentStoryId) { _ in
            vm.startProgressBarAnimation()
        }
        .onChange(of: scenePhase) { newPhase in
            vm.pasuseOrResumeProgressBarAnimationDependsOn(scenePhase: newPhase)
        }
    }
    
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        let storiesViewModel = StoriesViewModel()
        let story = storiesViewModel.stories[1]
        ProgressBar(
            storyId: story.id,
            storyViewModel: storiesViewModel.getStoryViewModelBy(storyId: story.id)
        )
    }
}
