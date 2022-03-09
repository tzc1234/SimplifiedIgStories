//
//  AVPlayer+Additions.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 09/03/2022.
//

import Foundation
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
        guard let duration = currentItem?.duration else { return }
        pause()
        seek(to: duration)
    }
}
