//
//  Settings.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 22/2/2022.
//

import Foundation
import UIKit

final class GlobalObject: ObservableObject {
    @Published var currentStoryIconIndex = -1
    var currentStoryIconFrame: CGRect = .zero
}
