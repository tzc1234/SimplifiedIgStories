//
//  ProgressBar.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 16/2/2022.
//

import SwiftUI

struct ProgressBar: View {
    @EnvironmentObject private var homeUIActionHandler: HomeUIActionHandler
    
    let story: Story
    @ObservedObject var animationHandler: StoryAnimationHandler
    
    var body: some View {
        HStack {
            Spacer(minLength: 2)
            
            ForEach(story.portions) { portion in
                ProgressBarPortion(
                    portionId: portion.id,
                    duration: portion.duration,
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
        .onChange(of: animationHandler.currentStoryId) { _ in
            animationHandler.startProgressBarAnimation()
        }
    }
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        let story = PreviewData.stories[0]
        ProgressBar(story: story, animationHandler: .preview)
    }
}
