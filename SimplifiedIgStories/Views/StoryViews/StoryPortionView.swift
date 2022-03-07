//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI

// *** In real enironment, images are loaded through internet.
// The case of failure should be considered.
struct StoryPortionView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPaused: Bool? = nil
    
    let index: Int
    let photoName: String?
    let videoUrl: URL?
    
    var body: some View {
        ZStack {
            Color.darkGray
            photoView
            videoView
        }
        // Pause video playing when inactive.
//        .onChange(of: scenePhase) { newPhase in
//            if videoUrl != nil {
//                if newPhase == .active {
//                    isPaused = false
//                } else if newPhase == .inactive {
//                    isPaused = true
//                }
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    isPaused = nil
//                }
//                
//            }
//        }
        
    }
}

struct StoryPortionView_Previews: PreviewProvider {
    static var previews: some View {
        StoryPortionView(index: 0, photoName: "sea1", videoUrl: nil)
    }
}

// MARK: compoents
extension StoryPortionView {
    @ViewBuilder private var photoView: some View {
        if let photoName = photoName {
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
    
    @ViewBuilder private var videoView: some View {
        if let videoUrl = videoUrl {
            AVPlayerControllerRepresentable(
                videoUrl: videoUrl,
                shouldLoop: false,
                isPaused: $isPaused
            )
        }
    }
}
