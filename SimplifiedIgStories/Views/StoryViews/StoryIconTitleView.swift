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
    let onTapAction: ((_ storyId: Int) -> Void)?
    
    var body: some View {
        VStack(alignment: .center, spacing: Self.vStackSpacing) {
            GeometryReader { geo in
                StoryIcon(story: story, onTapAction: onTapAction)
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
        let vm = StoriesViewModel(dataService: MockDataService())
        StoryIconTitleView(story: vm.stories[0], onTapAction: {_ in})
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
