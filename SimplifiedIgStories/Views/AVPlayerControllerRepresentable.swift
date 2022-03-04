//
//  AVPlayerControllerRepresentable.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import SwiftUI
import AVKit

struct AVPlayerControllerRepresentable: UIViewControllerRepresentable {
    let videoUrl: URL
    private let player: AVPlayer
    
    init(videoUrl: URL) {
        self.videoUrl = videoUrl
        self.player = AVPlayer(url: videoUrl)
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = false
        
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.playerItemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        player.play()
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator {
        private var parent: AVPlayerControllerRepresentable
        
        init(_ parent: AVPlayerControllerRepresentable) {
            self.parent = parent
        }
        
        @objc func playerItemDidPlayToEndTime() {
            parent.player.seek(to: .zero)
            parent.player.play()
        }
    }
}
