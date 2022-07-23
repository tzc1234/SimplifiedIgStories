//
//  StoryIconsView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct StoryIconsView: View {
    private let spacing: Double = 8.0
    @State private var storyIconFrames: [Int: CGRect] = [:]
    @EnvironmentObject private var homeUIActionHandler: HomeUIActionHandler
    
    @ObservedObject var vm: StoriesViewModel // Injected from HomeView
    let onTapIconAction: ((_ frame: CGRect?) -> Void)
    
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
            .onPreferenceChange(IdFramePreferenceKey.self) { idFrameDict in
               storyIconFrames = idFrameDict
            }
        }
        .task {
            await vm.fetchStories()
        }
    }
}

struct StoryIconsView_Previews: PreviewProvider {
    static var previews: some View {
        StoryIconsView(vm: StoriesViewModel(), onTapIconAction: {_ in})
    }
}

// MARK: helper functions
extension StoryIconsView {
    private func tapIconAction(storyId: Int) {
        onTapIconAction(storyIconFrames[storyId])
        
        guard let story = vm.getStoryById(storyId) else {
            return
        }
        
        if story.hasPortion {
            vm.setCurrentStoryId(storyId)
            homeUIActionHandler.showStoryContainer()
        } else if story.user.isCurrentUser {
            homeUIActionHandler.toggleStoryCamView()
        }
    }
}
