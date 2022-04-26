//
//  CubicTransitionModifier.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 11/03/2022.
//

import Foundation
import SwiftUI

// Cubic transition reference: https://www.youtube.com/watch?v=NTun83toSQQ&ab_channel=Kavsoft
struct CubicTransitionModifier: ViewModifier {
    let shouldRotate: Bool
    let offsetX: CGFloat
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                shouldRotate ? .degrees(getRotationDegree(offsetX: offsetX)) : .degrees(0),
                axis: (x: 0.0, y: 1.0, z: 0.0),
                anchor: offsetX > 0 ? .leading : .trailing,
                anchorZ: 0.0,
                perspective: 2.5
            )
    }
    
    private func getRotationDegree(offsetX: CGFloat) -> Double {
        let tempAngle = offsetX / (.screenWidth / 2)
        let rotationDegree = 20.0
        return tempAngle * rotationDegree
    }
}

extension View {
    func cubicTransition(shouldRotate: Bool, offsetX: CGFloat) -> some View {
        modifier(CubicTransitionModifier(shouldRotate: shouldRotate, offsetX: offsetX))
    }
}
