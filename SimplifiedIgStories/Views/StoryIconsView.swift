//
//  StoryIconsView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct StoryIconsView: View {
    @EnvironmentObject var modelData: ModelData
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 0) {
                Spacer(minLength: 8)
                
                ForEach(modelData.stories) { story in
                    NavigationLink {
                        StoryView()
                    } label: {
                        StoryIcon(avatar: story.user.avatar, title: story.user.name)
                            .frame(width: 90, height: 100)
                            .padding(.vertical, 6)
                    }

                    Spacer(minLength: 8)
                }
            }
        }
        
    }
}

struct StoryIconsView_Previews: PreviewProvider {
    static var previews: some View {
        StoryIconsView()
    }
}
