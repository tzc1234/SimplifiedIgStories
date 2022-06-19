//
//  AVCaptureVideoPreviewRepresentable.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 19/06/2022.
//

import SwiftUI

struct AVCaptureVideoPreviewRepresentable: UIViewRepresentable {
    @ObservedObject private var vm: StoryCamViewModel
    
    init(storyCamViewModel: StoryCamViewModel) {
        vm = storyCamViewModel
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        vm.videoPreviewLayer.frame = view.frame
        view.layer.addSublayer(vm.videoPreviewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}
