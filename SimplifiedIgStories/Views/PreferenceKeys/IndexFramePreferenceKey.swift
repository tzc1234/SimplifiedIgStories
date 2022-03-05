//
//  IndexFramePreferenceKey.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 5/3/2022.
//

import SwiftUI

struct IndexFramePreferenceKey: PreferenceKey {
    typealias IndexFrameDict = [Int: CGRect]
    
    static var defaultValue: IndexFrameDict = [:]
    
    static func reduce(value: inout IndexFrameDict, nextValue: () -> IndexFrameDict) {
        value.merge(nextValue()) { $1 }
    }
}
