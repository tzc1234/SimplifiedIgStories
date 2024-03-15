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
    
    @ObservedObject var vm: StoriesViewModel // Injected from HomeView
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 0) {
                Spacer(minLength: spacing)
                
                ForEach(vm.stories) { story in
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
            await vm.fetchStories()
        }
    }
    
    private func tapIconAction(storyId: Int) {
        guard let story = vm.getStory(by: storyId) else {
            return
        }
        
        if story.hasPortion {
            vm.setCurrentStoryId(storyId)
            homeUIActionHandler.showStoryContainer(storyId: storyId)
        } else if story.user.isCurrentUser {
            homeUIActionHandler.toggleStoryCamView()
        }
    }
}

struct StoryIconsView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = StoriesViewModel.preview
        StoryIconsView(vm: vm)
            .environmentObject(HomeUIActionHandler())
            .task {
                await vm.fetchStories()
            }
    }
}
