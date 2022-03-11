//
//  IdFramePreferenceKey.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 5/3/2022.
//

import SwiftUI

struct IdFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}
