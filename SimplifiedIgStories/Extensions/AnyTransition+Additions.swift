//
//  AnyTransition+Additions.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 24/2/2022.
//

import Foundation
import SwiftUI

extension AnyTransition {
    static func iOSNativeOpenAppTransition(offest: CGSize) -> AnyTransition {
        scale(scale: 0.08)
            .combined(with: .offset(offest))
            .combined(with: .opacity)
    }
}
