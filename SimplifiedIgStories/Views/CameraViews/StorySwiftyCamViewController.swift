//
//  SubSwiftyCamController.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 2/3/2022.
//

import UIKit
import SwiftyCam

class StorySwiftyCamViewController: SwiftyCamViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defaultCamera = .rear
        flashMode = .off
        pinchToZoom = false
        swipeToZoom = false
        tapToFocus = true
        maximumVideoDuration = .maximumVideoDuration
        audioEnabled = true
        doubleTapCameraSwitch = false
    }
}
