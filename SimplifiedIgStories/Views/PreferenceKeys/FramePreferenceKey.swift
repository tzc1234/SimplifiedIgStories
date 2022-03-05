//
//  FramePreferenceKey.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 5/3/2022.
//

import SwiftUI

struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
