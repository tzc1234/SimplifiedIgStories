//
//  CameraStatus.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/06/2022.
//

import AVKit

enum CameraStatus: Equatable {
    case sessionStarted
    case sessionStopped
    case cameraSwitched(position: CameraPosition)
}
