//
//  StoryIconsView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct StoryIconsView: View {
    static let spacing: Double = 8.0
    
    let stories: [Story]
    let onTapAction: ((Int) -> Void)
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 0) {
                Spacer(minLength: Self.spacing)
                
                ForEach(stories.indices) { index in
                    StoryIconTitleView(
                        index: index,
                        avatar: stories[index].user.avatar,
                        title: stories[index].user.title,
                        showPlusIcon: stories[index].user.isCurrentUser && stories[index].portions.count == 0,
                        onTapAction: onTapAction
                    )
                    .frame(width: 90, height: 100)
                    .padding(.vertical, 6)
                    
                    Spacer(minLength: Self.spacing)
                }
            }
        }
        
    }
    
}

struct StoryIconsView_Previews: PreviewProvider {
    static var previews: some View {
        StoryIconsView(stories: ModelData().stories, onTapAction: {_ in})
    }
}
