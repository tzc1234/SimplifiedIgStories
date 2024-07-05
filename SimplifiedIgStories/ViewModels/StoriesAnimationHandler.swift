//
//  StoriesAnimationHandler.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 20/03/2024.
//

import Foundation
import Combine

protocol StoriesHolder {
    var objectWillChange: ObservableObjectPublisher { get }
    var stories: [StoryDTO] { get }
}

final class StoriesAnimationHandler: ObservableObject, CurrentStoryAnimationHandler {
    @Published private(set) var currentStoryId = -1
    @Published var isDragging = false
    
    private var storyIdBeforeDragged: Int?
    private var cancellable: AnyCancellable?
    
    private let storiesHolder: StoriesHolder
    
    init(storiesHolder: StoriesHolder) {
        self.storiesHolder = storiesHolder
        
        cancellable = storiesHolder.objectWillChange
            .sink(receiveValue: { [weak self] _ in
                self?.objectWillChange.send()
            })
    }
}

extension StoriesAnimationHandler {
    var stories: [StoryDTO] {
        storiesHolder.stories
    }
    
    private var yourStoryId: Int? {
        stories.first(where: { $0.user.isCurrentUser })?.id
    }
    
    var currentStories: [StoryDTO] {
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
    
    func getPortionCount(by storyId: Int) -> Int {
        stories.first(where: { $0.id == storyId })?.portions.count ?? 0
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
