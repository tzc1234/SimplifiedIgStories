//
//  Settings.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 22/2/2022.
//

import Foundation
import UIKit
import SwiftUI

final class StoryGlobalObject: ObservableObject {
    @Published var currentStoryIndex = 0

    @Published var showContainer = false
    @Published var shouldAnimateCubicRotation = false
    var topSpacing = 0.0
    
    @Published var isDragging = false
    var storyIndexBeforeDragged = 0
    
    func closeStoryContainer() {
        // Don't use .spring(). If you switch the StoryContainer fast from one, close then open another,
        // there will be a weird behaviour. The StoryView can not be updated completely and broken.
        withAnimation(.easeInOut(duration: 0.3)) {
            showContainer.toggle()
        }
        shouldAnimateCubicRotation = false
    }
}
