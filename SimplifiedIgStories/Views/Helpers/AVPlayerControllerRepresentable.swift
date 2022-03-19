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
    @Binding private var player: AVPlayer?
    
    init(shouldLoop: Bool, player: Binding<AVPlayer?>) {
        self.shouldLoop = shouldLoop
        self._player = player
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
        
        do {
            try AVAudioSession.sharedInstance()
                .setCategory(
                    .playAndRecord,
                    mode: .default,
                    options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker]
                )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print(error.localizedDescription)
        }
        
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
    }
}
