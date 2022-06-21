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
            showFocusIndicator(at: point, in: gesture.view)
        }
        
        private func showFocusIndicator(at point: CGPoint, in view: UIView?) {
            let focusIndicator = UIImageView(image: UIImage(systemName: "circle.dashed"))
            focusIndicator.tintColor = .white
            focusIndicator.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            focusIndicator.center = point
            focusIndicator.contentMode = .scaleAspectFit
            focusIndicator.alpha = 0
            view?.addSubview(focusIndicator)
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
                focusIndicator.alpha = 1
                focusIndicator.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            } completion: { _ in
                UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut) {
                    focusIndicator.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                    focusIndicator.alpha = 0
                } completion: { _ in
                    focusIndicator.removeFromSuperview()
                }
            }
        }
    }
}
