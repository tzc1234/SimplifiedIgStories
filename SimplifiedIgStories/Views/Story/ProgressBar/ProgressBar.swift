//
//  ProgressBar.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/2/2022.
//

import SwiftUI

struct ProgressBar: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var homeUIActionHandler: HomeUIActionHandler
    
    let story: Story
    let currentStoryId: Int
    @ObservedObject var animationHandler: StoryAnimationHandler
    
    var body: some View {
        HStack {
            Spacer(minLength: 2)
            
            ForEach(story.portions) { portion in
                ProgressBarPortion(
                    portionId: portion.id,
                    duration: portion.duration,
                    storyId: story.id,
                    animationHandler: animationHandler
                )
                
                Spacer(minLength: 2)
            }
        }
        .padding(.horizontal, 10)
        .onChange(of: animationHandler.currentPortionAnimationStatus) { _ in
            animationHandler.performNextBarPortionAnimationWhenCurrentPortionFinished {
                homeUIActionHandler.closeStoryContainer(storyId: story.id)
            }
        }
        .onChange(of: currentStoryId) { _ in
            animationHandler.startProgressBarAnimation()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                animationHandler.resumePortionAnimation()
            } else if newPhase == .inactive {
                animationHandler.pausePortionAnimation()
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
            animationHandler: .preview(story: story, currentStoryHandler: storiesViewModel)
        )
    }
}
