//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI
import AVKit

// *** In real enironment, images are loaded through internet.
// The case of failure should be considered.
struct StoryPortionView: View {
    @State private var player: AVPlayer?
    
    let portion: Portion
    @ObservedObject private var storyViewModel: StoryViewModel
    
    init(portion: Portion, storyViewModel: StoryViewModel) {
        self.portion = portion
        self.storyViewModel = storyViewModel
    }
    
    var body: some View {
        ZStack {
            Color.darkGray
            photoView
            videoView
        }
        .onAppear {
            if let videoUrl = portion.videoUrl ?? portion.videoUrlFromCam {
                player = AVPlayer(url: videoUrl)
            }
        }
        .onChange(of: storyViewModel.barPortionAnimationStatuses[portion.id]) { animationStatus in
            guard let player = player else { return }
            guard let animationStatus = animationStatus else { return }
            
            switch animationStatus {
            case .inital:
                player.reset()
            case .start:
                player.replay()
            case .restart:
                player.replay()
            case .pause:
                player.pause()
            case .resume:
                player.play()
            case .finish:
                player.finish()
            }
        }
        
    }
}

struct StoryPortionView_Previews: PreviewProvider {
    static var previews: some View {
        let storiesViewModel = StoriesViewModel()
        let story = storiesViewModel.atLeastOnePortionStories[1]
        let portion = story.portions[0]
        StoryPortionView(
            portion: portion,
            storyViewModel: storiesViewModel.getStoryViewModelBy(story: story)
        )
    }
}

// MARK: components
extension StoryPortionView {
    @ViewBuilder private var photoView: some View {
        GeometryReader { geo in
            getImage()?
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(.ultraThinMaterial)
                .clipShape(Rectangle())
        }
        
        getImage()?
            .resizable()
            .scaledToFit()
    }
    
    @ViewBuilder private var videoView: some View {
        if player != nil {
            AVPlayerControllerRepresentable(
                shouldLoop: false,
                player: $player
            )
        }
    }
}

// MARK: functions
extension StoryPortionView {
    private func getImage() -> Image? {
        if let imageName = portion.imageName {
            return Image(imageName)
        } else if let imageUrl = portion.imageUrl,
                  let uiImage = LocalFileManager.instance.getImageBy(url: imageUrl) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}
