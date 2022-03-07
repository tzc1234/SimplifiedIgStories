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
    private let player: AVPlayer
    private let playerItem: AVPlayerItem
    @Binding private var isPaused: Bool?
    
    init(videoUrl: URL, shouldLoop: Bool, isPaused: Binding<Bool?>) {
        self.playerItem = AVPlayerItem(url: videoUrl)
        self.player = AVPlayer(playerItem: playerItem)
        
        self.shouldLoop = shouldLoop
        self._isPaused = isPaused
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = false
        
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.playerItemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        player.play()
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if isPaused == true {
            print("isPaused true, duration: \(playerItem.duration)")
            player.pause()
        } else if isPaused == false {
            print("isPaused false, duration: \(playerItem.duration)")
            player.play()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator {
        private var parent: AVPlayerControllerRepresentable
        
        init(_ parent: AVPlayerControllerRepresentable) {
            self.parent = parent
        }
        
        @objc func playerItemDidPlayToEndTime() {
            if parent.shouldLoop {
                parent.player.seek(to: .zero)
                parent.player.play()
            }
        }
    }
}
