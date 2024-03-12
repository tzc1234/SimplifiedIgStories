//
//  AnyTransition+Additions.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 24/2/2022.
//

import SwiftUI

extension AnyTransition {
    // Reference: https://stackoverflow.com/a/59408179
    static func openAppImitationTransition(scale: Double, offsetX: CGFloat, offsetY: CGFloat) -> AnyTransition {
        Self.scale(scale: scale, anchor: .top)
            .combined(with: .offset(x: offsetX, y: offsetY))
            .combined(with: .opacity)
    }
}

extension View {
    func openAppImitationTransition(scale: Double, offsetX: CGFloat, offsetY: CGFloat) -> some View {
        transition(.openAppImitationTransition(scale: scale, offsetX: offsetX, offsetY: offsetY))
    }
}
