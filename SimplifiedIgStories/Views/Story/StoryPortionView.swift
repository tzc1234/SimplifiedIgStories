//
//  StoryView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import SwiftUI
import AVKit

// *** In real environment, images are loaded through internet.
// The failure case should be considered.
struct StoryPortionView: View {
    @State private var player: AVPlayer?
    
    let portion: Portion
    @ObservedObject private var vm: StoryViewModel
    
    init(portion: Portion, storyViewModel: StoryViewModel) {
        self.portion = portion
        self.vm = storyViewModel
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
        .onChange(of: vm.barPortionAnimationStatusDict[portion.id]) { animationStatus in
            guard let player = player, let animationStatus = animationStatus else {
                return
            }
            
            switch animationStatus {
            case .initial:
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
        let storiesViewModel = StoriesViewModel(fileManager: LocalImageFileManager())
        let story = storiesViewModel.currentStories[0]
        let portion = story.portions[0]
        StoryPortionView(
            portion: portion,
            storyViewModel: StoryViewModel(
                storyId: story.id,
                storiesViewModel: storiesViewModel,
                fileManager: LocalImageFileManager(),
                mediaSaver: MediaFileSaver()
            )
        )
    }
}

// MARK: components
extension StoryPortionView {
    @ViewBuilder private var photoView: some View {
        GeometryReader { geo in
            image?
                .resizable()
                .scaledToFill()
                .overlay(.ultraThinMaterial)
                .clipShape(Rectangle())
        }
        
        image?
            .resizable()
            .scaledToFit()
    }
    
    @ViewBuilder private var videoView: some View {
        if player != nil {
            AVPlayerControllerRepresentable(
                shouldLoop: false,
                player: player
            )
        }
    }
}

// MARK: helpers
extension StoryPortionView {
    private var image: Image? {
        if let imageName = portion.imageName {
            return Image(imageName)
        } else if let imageUrl = portion.imageUrl,
                  let uiImage = vm.getImage(by: imageUrl) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}
