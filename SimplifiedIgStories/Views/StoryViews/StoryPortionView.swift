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
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var player: AVPlayer?
    
    let portionId: Int
    @ObservedObject private var storyViewModel: StoryViewModel
    let photoName: String?
    let videoUrl: URL?
    
    init(portionId: Int, storyViewModel: StoryViewModel, photoName: String?, videoUrl: URL?) {
        self.portionId = portionId
        self.storyViewModel = storyViewModel
        self.photoName = photoName
        self.videoUrl = videoUrl
    }
    
    var body: some View {
        ZStack {
            Color.darkGray
            photoView
            videoView
        }
        .onAppear {
            if let videoUrl = videoUrl {
                player = AVPlayer(url: videoUrl)
            }
        }
        .onChange(of: storyViewModel.barPortionAnimationStatuses[portionId]) { animationStatus in
            guard let animationStatus = animationStatus else { return }
            
            switch animationStatus {
            case .inital:
                player?.reset()
            case .start:
                player?.replay()
            case .restart:
                player?.replay()
            case .pause:
                player?.pause()
            case .resume:
                player?.play()
            case .finish:
                player?.finish()
            }
        }
        
    }
}

struct StoryPortionView_Previews: PreviewProvider {
    static var previews: some View {
        let storiesViewModel = StoriesViewModel(dataService: MockDataService())
        let story = storiesViewModel.atLeastOnePortionStories[1]
        let portion = story.portions[0]
        StoryPortionView(
            portionId: portion.id,
            storyViewModel: storiesViewModel.getStoryViewModelBy(story: story),
            photoName: "sea1",
            videoUrl: nil
        )
    }
}

// MARK: components
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
        if player != nil {
            AVPlayerControllerRepresentable(
                shouldLoop: false,
                player: $player
            )
        }
    }
}
