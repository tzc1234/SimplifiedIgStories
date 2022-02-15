//
//  StoryIconsView.swift
//  IgStoriesSwiftUI
//
//  Created by Tsz-Lung on 15/2/2022.
//

import SwiftUI

struct StoryIconsView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 0) {
                ForEach(0..<8) { index in
                    StoryIcon(title: "Person \(index)")
                        .frame(width: 90, height: 100)
                        .padding(.vertical, 6)
                }
            }
            
//            .frame(maxWidth: .infinity, minHeight: 90)
        }
        
    }
}

struct StoryIconsView_Previews: PreviewProvider {
    static var previews: some View {
        StoryIconsView()
            .preferredColorScheme(.dark)
    }
}
