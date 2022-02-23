//
//  Settings.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 22/2/2022.
//

import Foundation
import UIKit
import SwiftUI

final class GlobalObject: ObservableObject {
    var currentStoryIconIndex = 0
    @Published var currentStoryIconFrame: CGRect = .zero
    @Published var showContainer = false
}
