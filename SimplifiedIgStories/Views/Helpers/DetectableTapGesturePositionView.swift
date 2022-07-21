//
//  DetectableTapGesturePositionView.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 18/2/2022.
//

import UIKit
import SwiftUI

struct DetectableTapGesturePositionView: UIViewRepresentable {
    typealias TapCallback = (CGPoint) -> Void
    
    var tapCallback: TapCallback
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tap))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(tapCallback: tapCallback)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    class Coordinator: NSObject {
        var tapCallback: TapCallback
        
        init(tapCallback: @escaping TapCallback) {
            self.tapCallback = tapCallback
        }
        
        @objc func tap(gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            self.tapCallback(point)
        }
    }
}
