//
//  AVPlayerControllerRepresentable.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 4/3/2022.
//

import SwiftUI
import AVKit

struct AVPlayerControllerRepresentable: UIViewControllerRepresentable {
    let shouldLoop: Bool
    let player: AVPlayer?
    
    init(shouldLoop: Bool, player: AVPlayer?) {
        self.shouldLoop = shouldLoop
        self.player = player
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.playerItemDidPlayToEndTime),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        
        let vc = AVPlayerViewController()
        vc.showsPlaybackControls = false
        context.coordinator.avPlayerViewController = vc
        
        DispatchQueue.main.async {
            vc.player = player
            player?.play()
        }
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator {
        weak var avPlayerViewController: AVPlayerViewController?
        private var parent: AVPlayerControllerRepresentable
        
        init(_ parent: AVPlayerControllerRepresentable) {
            self.parent = parent
        }
        
        @objc func playerItemDidPlayToEndTime() {
            if parent.shouldLoop {
                parent.player?.seek(to: .zero)
                parent.player?.play()
            }
        }
        
        deinit {
            avPlayerViewController?.showsPlaybackControls = true
        }
    }
}
