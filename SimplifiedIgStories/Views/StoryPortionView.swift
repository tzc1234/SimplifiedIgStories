//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

struct StoryPortionView: View {
    let index: Int
    let photoName: String
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image(photoName)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(.ultraThinMaterial)
                    .clipShape(Rectangle())
            }
            
            Image(photoName)
                .resizable()
                .scaledToFit()
        }
    }
}

struct StoryPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        StoryPortionView(index: 0, photoName: "sea1")
    }
}
