//
//  StoryIconsView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct StoryIconsView: View {
    @EnvironmentObject private var homeUIActionHandler: HomeUIActionHandler
    
    @ObservedObject var animationHandler: StoriesAnimationHandler
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 0) {
                Spacer(minLength: 8.0)
                
                ForEach(animationHandler.stories) { story in
                    StoryIconTitleView(
                        story: story,
                        showPlusIcon: story.user.isCurrentUser && !story.hasPortion,
                        showStroke: story.hasPortion,
                        onTapAction: tapIconAction
                    )
                    .frame(width: 80, height: 90)
                    
                    Spacer(minLength: 8.0)
                }
            }
        }
    }
    
    private func tapIconAction(story: Story) {
        if story.hasPortion {
            animationHandler.setCurrentStoryId(story.id)
            homeUIActionHandler.showStoryContainer(storyId: story.id)
        } else if story.user.isCurrentUser {
            homeUIActionHandler.showStoryCameraView()
        }
    }
}

struct StoryIconsView_Previews: PreviewProvider {
    static var previews: some View {
        StoryIconsView(animationHandler: .preview)
            .environmentObject(HomeUIActionHandler())
    }
}
