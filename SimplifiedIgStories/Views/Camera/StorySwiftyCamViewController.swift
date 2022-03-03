//
//  SubSwiftyCamController.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 2/3/2022.
//

import Foundation
import UIKit

class StorySwiftyCamViewController: SwiftyCamViewController {
    static let maximumVideoDuration: Double = 10.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defaultCamera = .rear
        flashMode = .off
        pinchToZoom = false
        swipeToZoom = false
        tapToFocus = true
        maximumVideoDuration = Self.maximumVideoDuration
        audioEnabled = true
        doubleTapCameraSwitch = false
    }
    
}
