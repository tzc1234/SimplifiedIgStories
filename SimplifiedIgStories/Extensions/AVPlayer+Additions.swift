//
//  AVPlayer+Additions.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 09/03/2022.
//

import AVKit

extension AVPlayer {
    func reset() {
        pause()
        seek(to: .zero)
    }
    
    func replay() {
        seek(to: .zero)
        play()
    }
    
    func finish() {
        pause()
        guard let duration = currentItem?.duration, currentTime() != .zero else { return }
        seek(to: duration)
    }
}
