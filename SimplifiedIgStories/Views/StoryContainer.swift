//
//  StoryContainer.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct StoryContainer: View {
    let story: Story
    let topSpacing: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: topSpacing)
            StoryView(story: story)
        }
    }
}

struct StoryContainer_Previews: PreviewProvider {
    static let modelData = ModelData()
    static var previews: some View {
        StoryContainer(story: modelData.stories[0], topSpacing: 44.0)
    }
}
