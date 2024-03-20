//
//  StoriesAnimationHandler.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 20/03/2024.
//

import Foundation
import Combine

final class StoriesAnimationHandler: ObservableObject, CurrentStoryHandler {
    @Published private(set) var currentStoryId = -1
    @Published var shouldCubicRotation = false
    @Published var isDragging = false
    private var storyIdBeforeDragged: Int?
    
    private let getStories: () -> [Story]
    
    init(getStories: @escaping () -> [Story]) {
        self.getStories = getStories
    }
}

extension StoriesAnimationHandler {
    var stories: [Story] {
        getStories()
    }
    
    private var yourStoryId: Int? {
        stories.first(where: { $0.user.isCurrentUser })?.id
    }
    
    var currentStories: [Story] {
        if currentStoryId == yourStoryId {
            return stories.filter { $0.user.isCurrentUser }
        } else {
            return stories.filter { !$0.user.isCurrentUser }
        }
    }
    
    var isSameStoryAfterDragging: Bool {
        currentStoryId == storyIdBeforeDragged
    }
    
    var currentStoryIndex: Int? {
        currentStories.firstIndex(where: { $0.id == currentStoryId })
    }
    
    var firstCurrentStoryId: Int? {
        currentStories.first?.id
    }
    
    var lastCurrentStoryId: Int? {
        currentStories.last?.id
    }
    
    var isAtFirstStory: Bool {
        currentStoryId == firstCurrentStoryId
    }
    
    var isAtLastStory: Bool {
        currentStoryId == lastCurrentStoryId
    }
}

extension StoriesAnimationHandler {
    func getIsDraggingPublisher() -> AnyPublisher<Bool, Never> {
        $isDragging.eraseToAnyPublisher()
    }
    
    func saveStoryIdBeforeDragged() {
        storyIdBeforeDragged = currentStoryId
    }
    
    func setCurrentStoryId(_ storyId: Int) {
        guard stories.map(\.id).contains(storyId) else { return }
        
        currentStoryId = storyId
    }
    
    func moveToPreviousStory() {
        guard let currentStoryIndex else { return }
        
        let previousStoryIndex = currentStoryIndex-1
        if previousStoryIndex >= 0 {
            currentStoryId = currentStories[previousStoryIndex].id
        }
    }
    
    func moveToNextStory() {
        guard let currentStoryIndex else { return }
        
        let nextStoryIndex = currentStoryIndex+1
        if nextStoryIndex < currentStories.count {
            currentStoryId = currentStories[nextStoryIndex].id
        }
    }
}
