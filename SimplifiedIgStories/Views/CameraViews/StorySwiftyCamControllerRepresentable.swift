//
//  SwiftyCamControllerRepresentable.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 2/3/2022.
//

import UIKit
import SwiftUI

struct StorySwiftyCamControllerRepresentable: UIViewControllerRepresentable {
    @ObservedObject private var vm: StoryCamViewModel
    
    init(storyCamViewModel: StoryCamViewModel) {
        self.vm = storyCamViewModel
    }
    
    func makeUIViewController(context: Context) -> StorySwiftyCamViewController {
        let vc = StorySwiftyCamViewController()
        vm.subscribe(to: vc.getPublisher())
        return vc
    }

    func updateUIViewController(_ uiViewController: StorySwiftyCamViewController, context: Context) {
        if vm.cameraSelection != uiViewController.currentCamera {
            uiViewController.switchCamera()
        }
        
        if vm.flashMode.swiftyCamFlashMode != uiViewController.flashMode {
            uiViewController.flashMode = vm.flashMode.swiftyCamFlashMode
        }
        
        if vm.shouldPhotoTake {
            uiViewController.takePhoto()
        }
        
        switch vm.videoRecordingStatus {
        case .none:
            break
        case .start:
            uiViewController.startVideoRecording()
        case .stop:
            uiViewController.stopVideoRecording()
        }
    }
}
