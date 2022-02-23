//
//  StoryContainer.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/2/2022.
//

import SwiftUI

struct StoryContainer: View {
    let topSpacing: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: topSpacing)
            StoryView()
        }
    }
}

struct StoryContainer_Previews: PreviewProvider {
    static var previews: some View {
        StoryContainer(topSpacing: 44.0)
    }
}
