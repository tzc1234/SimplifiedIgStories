//
//  StoriesViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 7/3/2022.
//

import Foundation
import SwiftUI

final class StoriesViewModel: ObservableObject {
    @Published var stories: [Story] = []
    
    @Published var currentStoryId = 0
    @Published var showContainer = false
    @Published var shouldCubicRotation = false
    @Published var showStoryCamView = false
    @Published var isDragging = false
    
    var storyIdBeforeDragged = 0
    
    // key: storyId, value: storyIconFrame displayed in HomeView
    var storyIconFrames: [Int: CGRect] = [:]
    
    // key: storyId
    var storyViewModels: [Int: StoryViewModel] = [:]
    
    private let dataService: DataService
    
    init(dataService: DataService = AppDataService()) {
        self.dataService = dataService
        self.loadStories()
    }
}

// MARK: computed variables
extension StoriesViewModel {
    var yourStoryId: Int? {
        stories.first(where: { $0.user.isCurrentUser })?.id
    }
    
    var yourStoryIndex: Int? {
        stories.firstIndex(where: { $0.user.isCurrentUser })
    }
    
    var lastPortionId: Int {
        currentStories.flatMap(\.portions).map(\.id).max() ?? -1
    }
    
    var currentStories: [Story] {
        if currentStoryId == yourStoryId {
            return stories.filter { $0.user.isCurrentUser }
        } else {
            return stories.filter { !$0.user.isCurrentUser }
        }
    }
    
    var currentStoryIconFrame: CGRect {
        storyIconFrames[currentStoryId] ?? .zero
    }
    
    var isSameStoryAfterDragged: Bool {
        currentStoryId == storyIdBeforeDragged
    }
}

// MARK: functions
extension StoriesViewModel {
    func loadStories() {
        stories = dataService.loadStories()
    }
    
    func getStoryViewModelBy(storyId: Int) -> StoryViewModel {
        guard let existingStoryViewModel = storyViewModels[storyId] else {
            let newStoryViewModel = StoryViewModel(storyId: storyId, storiesViewModel: self)
            storyViewModels[storyId] = newStoryViewModel
            return newStoryViewModel
        }
        return existingStoryViewModel
    }
    
    func removeAllStoryViewModel() {
        storyViewModels = [:]
    }
    
    func toggleStoryCamView() {
        withAnimation(.default) { showStoryCamView.toggle() }
    }
    
    func tapStoryIcon(storyId: Int) {
        guard let story = stories.first(where: { $0.id == storyId }) else {
            return
        }
        
        if story.hasPortion {
            showStoryContainer(storyId: storyId)
        } else if story.user.isCurrentUser {
            toggleStoryCamView()
        }
    }
}

// MARK: functions for StoryContainer
extension StoriesViewModel {
    func getContainerOffset(width: CGFloat) -> CGFloat {
        guard
            let index =
                currentStories.firstIndex(where: { $0.id == currentStoryId })
        else {
            return 0.0
        }
        return -CGFloat(index) * width
    }
    
    func showStoryContainer(storyId: Int) {
        currentStoryId = storyId
        
        let animationDuration = 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: animationDuration)) { [weak self] in
                self?.showContainer.toggle()
            }
        }
    }
    
    func closeStoryContainer() {
        // Don't use .spring(). If you switch the StoryContainer fast from one, close then open another,
        // there will be a weird behaviour. The StoryView can not be updated completely and broken.
        withAnimation(.easeInOut(duration: 0.3)) {
            showContainer.toggle()
        }
    }
    
    func dragStoryContainer() {
        isDragging = true // Start dragging.
        storyIdBeforeDragged = currentStoryId
    }
    
    func endDraggingStoryContainer(offset: CGFloat) {
        // Imitate the close behaviour of IG story when dragging right in the first story,
        // or dragging left in the last story, close the container.
        if (currentStoryId == currentStories.first?.id && offset > 0.2) ||
            (currentStoryId == currentStories.last?.id && offset < -0.2) {
            closeStoryContainer()
        } else { // Go to previous or next.
            guard
                let currentStoryIndex =
                    currentStories.firstIndex(where: { $0.id == currentStoryId })
            else {
                return
            }
            
            let nextIndex = Int((CGFloat(currentStoryIndex) - offset).rounded())
            let adjustedNextIndex = min(nextIndex, stories.count - 1)
            currentStoryId = currentStories[adjustedNextIndex].id
        }
        
        isDragging = false // End dragging.
    }
}
