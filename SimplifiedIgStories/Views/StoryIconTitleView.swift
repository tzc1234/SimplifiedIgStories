//
//  StoryIconTitleView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct StoryIconTitleView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let index: Int
    let avatar: String
    let title: String?
    let showPlusIcon: Bool
    let onTapAction: ((Int) -> Void)
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            StoryIcon(index: index, avatar: avatar, showPlusIcon: showPlusIcon, onTapAction: onTapAction)
        
            if title != nil {
                titleText
            }
        }
    }
    
    var titleText: some View {
        Text(title ?? "")
            .font(.caption)
            .lineLimit(1)
            .foregroundColor(colorScheme == .light ? .black : .white)
            .padding(.horizontal, 4)
    }
    
}

struct StoryIconTitleView_Previews: PreviewProvider {
    static var previews: some View {
        StoryIconTitleView(index: 0, avatar: "avatar", title: "Person0", showPlusIcon: false, onTapAction: {_ in})
    }
}
