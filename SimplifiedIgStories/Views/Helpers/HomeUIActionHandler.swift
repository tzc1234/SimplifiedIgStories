//
//  HomeUIActionHandler.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 23/07/2022.
//

import SwiftUI

final class HomeUIActionHandler: ObservableObject {
    typealias StoryId = Int
    typealias IconFrame = CGRect
    
    @Published private(set) var showContainer = false
    @Published var showStoryCamView = false
    
    var storyIconFrameDict: [StoryId: IconFrame] = [:]
    @Published private(set) var currentIconFrame: IconFrame = .zero
    
    var postImageAction: ((UIImage) -> Void)?
    var postVideoAction: ((URL) -> Void)?
    var tapStoryCameraCloseAction: (() -> Void)?
    
    func showStoryContainer(storyId: Int?) {
        updateCurrentIconFrame(storyId: storyId)
        withAnimation(.easeInOut(duration: 0.3)) {
            showContainer = true
        }
    }

    func closeStoryContainer(storyId: Int?) {
        updateCurrentIconFrame(storyId: storyId)
        // Don't use .spring(). If you switch the StoryContainer fast from one, close then open another,
        // there will be a weird behaviour. The StoryView cannot be updated completely and broken.
        withAnimation(.easeInOut(duration: 0.3)) {
            showContainer = false
        }
    }
    
    func toggleStoryCamView() {
        withAnimation(.default) {
            showStoryCamView.toggle()
        }
    }
    
    private func updateCurrentIconFrame(storyId: Int?) {
        guard let storyId, let iconFrame = storyIconFrameDict[storyId] else {
            return
        }
        
        currentIconFrame = iconFrame
    }
}
