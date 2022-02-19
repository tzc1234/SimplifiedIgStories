//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

struct StoryDisplayView: View {
    @State var index = 0
    let photoName: String
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image(photoName)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                    .overlay(.ultraThinMaterial)
            }
            
            Image(photoName)
                .resizable()
                .scaledToFit()
        }
    }
    
    func onSetIndex(_ index: Int) -> some View {
        self.index = index
        return self
    }
    
}

struct StoryPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        StoryDisplayView(photoName: "sea1")
    }
}
