//
//  AnyTransition+Additions.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 24/2/2022.
//

import Foundation
import SwiftUI

extension AnyTransition {
    static func iOSOpenAppTransition(sacle: Double, offestX: CGFloat, offsetY: CGFloat) -> AnyTransition {
        scale(scale: sacle, anchor: .top)
            .combined(with: .offset(x: offestX, y: offsetY))
            .combined(with: .opacity)
    }
}
