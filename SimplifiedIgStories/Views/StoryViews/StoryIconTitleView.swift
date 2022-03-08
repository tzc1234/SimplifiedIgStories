//
//  StoryIconTitleView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct StoryIconTitleView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let story: Story
    let onTapAction: ((_ storyId: Int) -> Void)
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            StoryIcon(story: story, onTapAction: onTapAction)
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
