//
//  StoryIconTitleView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct StoryIconTitleView: View {
    static let vStackSpacing = 4.0
    
    @Environment(\.colorScheme) var colorScheme
    
    let story: Story
    let showPlusIcon: Bool
    let showStroke: Bool
    let onTapAction: ((_ storyId: Int) -> Void)?
    
    init(story: Story, showPlusIcon: Bool = false, showStroke: Bool = true, onTapAction: ((_ storyId: Int) -> Void)? = nil) {
        self.story = story
        self.showPlusIcon = showPlusIcon
        self.showStroke = showStroke
        self.onTapAction = onTapAction
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: Self.vStackSpacing) {
            GeometryReader { geo in
                StoryIcon(story: story, showPlusIcon: showPlusIcon, showStroke: showStroke, onTapAction: onTapAction)
                    .preference(
                        key: IdFramePreferenceKey.self,
                        value: [story.id: geo.frame(in: .global)]
                    )
            }
            
            titleText
        }
    }
}

struct StoryIconTitleView_Previews: PreviewProvider {
    static var previews: some View {
        StoryIconTitleView(story: StoriesViewModel().stories[0])
    }
}

// MARK: computed variables
extension StoryIconTitleView {
    var titleText: some View {
        Text(story.user.title)
            .font(.caption)
            .lineLimit(1)
            .foregroundColor(colorScheme == .light ? .black : .white)
            .padding(.horizontal, 4)
    }
}
