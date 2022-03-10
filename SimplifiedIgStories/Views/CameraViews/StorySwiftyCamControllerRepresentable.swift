//
//  SwiftyCamControllerRepresentable.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 2/3/2022.
//

import UIKit
import SwiftUI

struct StorySwiftyCamControllerRepresentable: UIViewControllerRepresentable {
    @ObservedObject private var storyCamGlobal: StoryCamGlobal
    
    init(storyCamGlobal: StoryCamGlobal) {
        self.storyCamGlobal = storyCamGlobal
    }
    
    func makeUIViewController(context: Context) -> StorySwiftyCamViewController {
        let vc = StorySwiftyCamViewController()
        vc.cameraDelegate = context.coordinator
        
        return vc
    }

    func updateUIViewController(_ uiViewController: StorySwiftyCamViewController, context: Context) {
        if storyCamGlobal.cameraSelection != uiViewController.currentCamera {
            uiViewController.switchCamera()
        }
        
        if storyCamGlobal.flashMode.swiftyCamFlashMode != uiViewController.flashMode {
            uiViewController.flashMode = storyCamGlobal.flashMode.swiftyCamFlashMode
        }
        
        if storyCamGlobal.shouldPhotoTake {
            uiViewController.takePhoto()
        }
        
        switch storyCamGlobal.videoRecordingStatus {
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
            print("Session did start running")
            parent.storyCamGlobal.enableVideoRecordBtn = true
        }
        
        func swiftyCamSessionDidStopRunning(_ swiftyCam: SwiftyCamViewController) {
            print("Session did stop running")
            parent.storyCamGlobal.enableVideoRecordBtn = false
        }
        
        func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
            parent.storyCamGlobal.lastTakenImage = photo
            parent.storyCamGlobal.photoDidTake = true
        }
        
        func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
            print("Did Begin Recording Viedo")
        }
        
        func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
            print("Did finish Recording Video")
            parent.storyCamGlobal.videoRecordingStatus = .none
        }
        
        func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
            print("VideoUrl: \(url)")
            parent.storyCamGlobal.lastVideoUrl = url
            parent.storyCamGlobal.videoDidRecord = true
        }
    }
}
