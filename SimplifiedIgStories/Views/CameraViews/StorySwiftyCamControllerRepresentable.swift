//
//  SwiftyCamControllerRepresentable.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 2/3/2022.
//

import UIKit
import SwiftUI

struct StorySwiftyCamControllerRepresentable: UIViewControllerRepresentable {
    @ObservedObject private var storyCamViewModel: StoryCamViewModel
    
    init(storyCamGlobal: StoryCamViewModel) {
        self.storyCamViewModel = storyCamGlobal
    }
    
    func makeUIViewController(context: Context) -> StorySwiftyCamViewController {
        let vc = StorySwiftyCamViewController()
        vc.cameraDelegate = context.coordinator
        
        return vc
    }

    func updateUIViewController(_ uiViewController: StorySwiftyCamViewController, context: Context) {
        if storyCamViewModel.cameraSelection != uiViewController.currentCamera {
            uiViewController.switchCamera()
        }
        
        if storyCamViewModel.flashMode.swiftyCamFlashMode != uiViewController.flashMode {
            uiViewController.flashMode = storyCamViewModel.flashMode.swiftyCamFlashMode
        }
        
        if storyCamViewModel.shouldPhotoTake {
            uiViewController.takePhoto()
        }
        
        switch storyCamViewModel.videoRecordingStatus {
        case .none:
            break
        case .start:
            uiViewController.startVideoRecording()
        case .stop:
            uiViewController.stopVideoRecording()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, SwiftyCamViewControllerDelegate {
        private var parent: StorySwiftyCamControllerRepresentable
        
        init(_ parent: StorySwiftyCamControllerRepresentable) {
            self.parent = parent
        }
        
        // MARK: SwiftyCamViewControllerDelegate
        func swiftyCamSessionDidStartRunning(_ swiftyCam: SwiftyCamViewController) {
            print("Camera session did start running")
            parent.storyCamViewModel.enableVideoRecordBtn = true
        }
        
        func swiftyCamSessionDidStopRunning(_ swiftyCam: SwiftyCamViewController) {
            print("Camera session did stop running")
            parent.storyCamViewModel.enableVideoRecordBtn = false
        }
        
        func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
            parent.storyCamViewModel.lastTakenImage = photo
            parent.storyCamViewModel.photoDidTake = true
        }
        
        func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
            print("Did Begin Recording Viedo")
        }
        
        func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
            print("Did finish Recording Video")
            parent.storyCamViewModel.videoRecordingStatus = .none
        }
        
        func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
            print("VideoUrl: \(url)")
            parent.storyCamViewModel.lastVideoUrl = url
            parent.storyCamViewModel.videoDidRecord = true
        }
    }
}
