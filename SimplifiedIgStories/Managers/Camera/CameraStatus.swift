//
//  CameraStatus.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/06/2022.
//

import AVFoundation
import AVKit

enum CameraStatus {
    case sessionStarted
    case sessionStopped
    case cameraSwitched(camPosition: CameraPosition)
}
