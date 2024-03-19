//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI
import AVKit

// *** In real environment, images are loaded through internet. The failure case should be considered.
struct StoryPortionView: View {
    @State private var player: AVPlayer?
    
    let portion: Portion
    @ObservedObject var animationHandler: StoryAnimationHandler
    
    var body: some View {
        ZStack {
            Color.darkGray
            photoView
            videoView
        }
        .onAppear {
            if let videoURL = portion.videoURL {
                player = AVPlayer(url: videoURL)
            }
        }
        .onChange(of: animationHandler.barPortionAnimationStatusDict[portion.id]) { status in
            guard let player else { return }
            
            switch status {
            case .initial:
                player.reset()
            case .start, .restart:
                player.replay()
            case .pause:
                player.pause()
            case .resume:
                player.play()
            case .finish:
                player.finish()
            case .none:
                break
            }
        }
    }
}

extension StoryPortionView {
    @ViewBuilder
    private var photoView: some View {
        AsyncImage(url: portion.imageURL) { image in
            ZStack {
                GeometryReader { _ in
                    image
                        .resizable()
                        .scaledToFill()
                        .overlay(.ultraThinMaterial)
                        .clipShape(Rectangle())
                }
                
                image
                    .resizable()
                    .scaledToFit()
            }
        } placeholder: {
            Color.darkGray
        }
    }
    
    @ViewBuilder 
    private var videoView: some View {
        if player != nil {
            AVPlayerControllerRepresentable(
                shouldLoop: false,
                player: player
            )
        }
    }
}

struct StoryPortionView_Previews: PreviewProvider {
    static var previews: some View {
        let storiesViewModel = StoriesViewModel.preview
        let story = storiesViewModel.currentStories[0]
        let portion = story.portions[0]
        StoryPortionView(
            portion: portion,
            animationHandler: .preview(story: story)
        )
    }
}
