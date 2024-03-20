//
//  StoryIconsView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct StoryIconsView: View {
    private let spacing: Double = 8.0
    @EnvironmentObject private var homeUIActionHandler: HomeUIActionHandler
    
    @ObservedObject var storiesViewModel: StoriesViewModel
    @ObservedObject var animationHandler: StoriesAnimationHandler
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 0) {
                Spacer(minLength: spacing)
                
                ForEach(storiesViewModel.stories) { story in
                    StoryIconTitleView(
                        story: story,
                        showPlusIcon: story.user.isCurrentUser && !story.hasPortion,
                        showStroke: story.hasPortion,
                        onTapAction: tapIconAction
                    )
                    .frame(width: 80, height: 90)
                    
                    Spacer(minLength: spacing)
                }
            }
        }
        .task {
            await storiesViewModel.fetchStories()
        }
    }
    
    private func tapIconAction(story: Story) {
        if story.hasPortion {
            animationHandler.setCurrentStoryId(story.id)
            homeUIActionHandler.showStoryContainer(storyId: story.id)
        } else if story.user.isCurrentUser {
            homeUIActionHandler.toggleStoryCamView()
        }
    }
}

struct StoryIconsView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = StoriesViewModel.preview
        StoryIconsView(storiesViewModel: vm, animationHandler: .preview)
            .environmentObject(HomeUIActionHandler())
            .task {
                await vm.fetchStories()
            }
    }
}
