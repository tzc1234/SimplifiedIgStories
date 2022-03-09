//
//  ProgressBar.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/2/2022.
//

import SwiftUI

struct ProgressBar: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var storiesViewModel: StoriesViewModel
    
    let story: Story
    @ObservedObject private var storyViewModel: StoryViewModel
    
    init(story: Story, storyViewModel: StoryViewModel) {
        self.story = story
        self.storyViewModel = storyViewModel
    }
    
    var body: some View {
        HStack {
            Spacer(minLength: 2)
            
            ForEach(story.portions) { portion in
                ProgressBarPortion(
                    portionId: portion.id,
                    duration: portion.duration,
                    story: story,
                    storyViewModel: storyViewModel
                )
                
                Spacer(minLength: 2)
            }
        }
        .padding(.horizontal, 10)
        .onChange(of: storyViewModel.portionTransitionDirection) { newDirection in
            storyViewModel.performProgressBarTransitionTo(newDirection)
        }
        .onChange(of: storyViewModel.currentPortionAnimationStatus) { newStatus in
            storyViewModel.performNextProgressBarPortionAnimationWhenFinished(newStatus)
        }
        .onChange(of: storiesViewModel.isDragging) { isDragging in
            storyViewModel.performProgressBarTransitionWhen(isDragging: isDragging)
        }
        .onChange(of: storiesViewModel.currentStoryId) { _ in
            storyViewModel.startProgressBarAnimation()
        }
        .onChange(of: scenePhase) { newPhase in
            storyViewModel.pasuseOrResumeProgressBarAnimationDependsOn(scenePhase: newPhase)
        }
    }
    
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        let storiesViewModel = StoriesViewModel(dataService: MockDataService())
        let story = storiesViewModel.stories[1]
        ProgressBar(story: story, storyViewModel: storiesViewModel.getStoryViewModelBy(story: story))
            .environmentObject(storiesViewModel)
    }
}
