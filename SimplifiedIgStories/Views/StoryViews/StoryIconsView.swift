//
//  StoryIconsView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct StoryIconsView: View {
    let spacing: Double = 8.0
    
    let stories: [Story]
    let onTapAction: ((_ storyId: Int) -> Void)
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 0) {
                Spacer(minLength: spacing)
                
                ForEach(stories) { story in
                    StoryIconTitleView(
                        story: story,
                        showPlusIcon: story.user.isCurrentUser && !story.hasPortion,
                        showStroke: story.hasPortion,
                        onTapAction: onTapAction
                    )
                    .frame(width: 80, height: 90)
                    
                    Spacer(minLength: spacing)
                }
            }
        }
        
    }
}

struct StoryIconsView_Previews: PreviewProvider {
    static var previews: some View {
        StoryIconsView(stories: StoriesViewModel().stories, onTapAction: {_ in})
    }
}
