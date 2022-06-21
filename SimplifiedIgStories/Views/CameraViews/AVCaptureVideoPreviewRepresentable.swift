//
//  AVCaptureVideoPreviewRepresentable.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/06/2022.
//

import SwiftUI
import UIKit

struct AVCaptureVideoPreviewRepresentable: UIViewRepresentable {
    @ObservedObject private(set) var vm: StoryCamViewModel
    
    init(storyCamViewModel: StoryCamViewModel) {
        vm = storyCamViewModel
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        vm.videoPreviewLayer.frame = view.frame
        view.layer.addSublayer(vm.videoPreviewLayer)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tap(gesture:)))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator {
        private let parent: AVCaptureVideoPreviewRepresentable
        
        init(parent: AVCaptureVideoPreviewRepresentable) {
            self.parent = parent
        }
        
        @MainActor @objc func tap(gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            parent.vm.videoPreviewTapPoint = point
        }
    }
}
