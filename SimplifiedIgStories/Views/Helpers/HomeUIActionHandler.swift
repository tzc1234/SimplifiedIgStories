//
//  HomeUIActionHandler.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/07/2022.
//

import SwiftUI

final class HomeUIActionHandler: ObservableObject {
    typealias StoryID = Int
    typealias IconFrame = CGRect
    
    @Published private(set) var isContainerShown = false
    @Published private(set) var isStoryCameraViewShown = false
    
    var storyIconFrameDict: [StoryID: IconFrame] = [:]
    @Published private(set) var currentIconFrame: IconFrame = .zero
    
    var postImageAction: ((UIImage) -> Void)?
    var postVideoAction: ((URL) -> Void)?
    
    func showStoryContainer(storyId: Int?) {
        updateCurrentIconFrame(storyId: storyId)
        withAnimation(.easeInOut(duration: 0.3)) {
            isContainerShown = true
        }
    }

    func closeStoryContainer(storyId: StoryID?) {
        updateCurrentIconFrame(storyId: storyId)
        // Don't use .spring(). If you switch the StoryContainer fast from one, close then open another,
        // there will be a weird behaviour. The StoryView cannot be updated completely and broken.
        withAnimation(.easeInOut(duration: 0.3)) {
            isContainerShown = false
        }
    }
    
    func showStoryCameraView() {
        withAnimation(.default) {
            isStoryCameraViewShown = true
        }
    }
    
    func closeStoryCameraView() {
        withAnimation(.default) {
            isStoryCameraViewShown = false
        }
    }
    
    private func updateCurrentIconFrame(storyId: StoryID?) {
        guard let storyId, let iconFrame = storyIconFrameDict[storyId] else {
            return
        }
        
        currentIconFrame = iconFrame
    }
}
