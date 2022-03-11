//
//  AnyTransition+Additions.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 24/2/2022.
//

import Foundation
import SwiftUI

extension AnyTransition {
    // Reference: https://stackoverflow.com/a/59408179
    static func openAppLikeTransition(sacle: Double, offestX: CGFloat, offsetY: CGFloat) -> AnyTransition {
        scale(scale: sacle, anchor: .top)
            .combined(with: .offset(x: offestX, y: offsetY))
            .combined(with: .opacity)
    }
}

extension View {
    func openAppLikeTransition(sacle: Double, offestX: CGFloat, offsetY: CGFloat) -> some View {
        transition(.openAppLikeTransition(sacle: sacle, offestX: offestX, offsetY: offsetY))
    }
}
