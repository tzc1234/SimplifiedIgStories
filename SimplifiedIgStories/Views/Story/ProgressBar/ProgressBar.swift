//
//  ProgressBar.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/2/2022.
//

import SwiftUI
import Combine

struct ProgressBar: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var homeUIActionHandler: HomeUIActionHandler
    
    let story: Story
    let currentStoryId: Int
    @ObservedObject var storyViewModel: StoryViewModel
    
    var body: some View {
        HStack {
            Spacer(minLength: 2)
            
            ForEach(story.portions) { portion in
                ProgressBarPortion(
                    portionId: portion.id,
                    duration: portion.duration,
                    storyId: story.id,
                    storyViewModel: storyViewModel
                )
                
                Spacer(minLength: 2)
            }
        }
        .padding(.horizontal, 10)
        .onChange(of: storyViewModel.currentPortionAnimationStatus) { _ in
            storyViewModel.performNextBarPortionAnimationWhenCurrentPortionFinished {
                homeUIActionHandler.closeStoryContainer(storyId: story.id)
            }
        }
        .onChange(of: currentStoryId) { _ in
            storyViewModel.startProgressBarAnimation()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                storyViewModel.resumePortionAnimation()
            } else if newPhase == .inactive {
                storyViewModel.pausePortionAnimation()
            }
        }
    }
    
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        let storiesViewModel = StoriesViewModel.preview
        let story = storiesViewModel.stories[1]
        ProgressBar(
            story: story, 
            currentStoryId: story.id,
            storyViewModel: StoryViewModel(
                storyId: story.id,
                parentViewModel: storiesViewModel,
                fileManager: LocalFileManager(),
                mediaSaver: DummyMediaSaver()
            )
        )
    }
}
