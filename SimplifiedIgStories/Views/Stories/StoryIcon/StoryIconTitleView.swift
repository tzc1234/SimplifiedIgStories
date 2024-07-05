//
//  StoryIconTitleView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct StoryIconTitleView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let story: StoryDTO
    let showPlusIcon: Bool
    let showStroke: Bool
    let onTapAction: ((StoryDTO) -> Void)?
    
    init(story: StoryDTO, showPlusIcon: Bool = false, showStroke: Bool = true, onTapAction: ((StoryDTO) -> Void)? = nil) {
        self.story = story
        self.showPlusIcon = showPlusIcon
        self.showStroke = showStroke
        self.onTapAction = onTapAction
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 4.0) {
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
    
    var titleText: some View {
        Text(story.user.title)
            .font(.caption)
            .lineLimit(1)
            .foregroundColor(colorScheme == .light ? .black : .white)
            .padding(.horizontal, 4)
    }
}

struct StoryIconTitleView_Previews: PreviewProvider {
    static var previews: some View {
        StoryIconTitleView(story: PreviewData.stories[0])
            .previewLayout(.sizeThatFits)
    }
}
