//
//  StoriesViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 7/3/2022.
//

import SwiftUI

final class StoriesViewModel: ObservableObject {
    @Published var stories: [Story] = []
    
    @Published var currentStoryId = 0
    @Published private(set) var showContainer = false
    @Published var shouldCubicRotation = false
    @Published private(set) var showStoryCamView = false
    @Published private(set) var isDragging = false
    
    var storyIdBeforeDragged = 0
    
    // key: storyId, value: storyIconFrame displayed in HomeView
    var storyIconFrames: [Int: CGRect] = [:]
    
    private let dataService: DataService
    
    init(dataService: DataService = AppDataService()) {
        self.dataService = dataService
    }
}

// MARK: computed variables
extension StoriesViewModel {
    var yourStoryId: Int? {
        stories.first(where: { $0.user.isCurrentUser })?.id
    }
    
    var yourStoryIdx: Int? {
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
    @MainActor func fetchStories() async {
        do {
            self.stories = try await dataService.fetchStories()
        } catch {
            let errMsg = (error as? DataServiceError)?.errMsg ?? error.localizedDescription
            print(errMsg)
        }
    }
    
    func toggleStoryCamView() {
        withAnimation(.default) { showStoryCamView.toggle() }
    }
    
    func tapStoryIcon(with storyId: Int) {
        guard let story = stories.first(where: { $0.id == storyId }) else {
            return
        }
        
        if story.hasPortion {
            showStoryContainer(by: storyId)
        } else if story.user.isCurrentUser {
            toggleStoryCamView()
        }
    }
}

// MARK: functions for StoryContainer
extension StoriesViewModel {
    func getContainerOffset(by width: CGFloat) -> CGFloat {
        guard
            let index =
                currentStories.firstIndex(where: { $0.id == currentStoryId })
        else {
            return 0.0
        }
        return -CGFloat(index) * width
    }
    
    func showStoryContainer(by storyId: Int) {
        currentStoryId = storyId
        withAnimation(.easeInOut(duration: 0.3)) {
            showContainer = true
        }
    }
    
    func closeStoryContainer() {
        // Don't use .spring(). If you switch the StoryContainer fast from one, close then open another,
        // there will be a weird behaviour. The StoryView can not be updated completely and broken.
        withAnimation(.easeInOut(duration: 0.3)) {
            showContainer = false
        }
    }
    
    func dragStoryContainer() {
        isDragging = true // Start dragging.
        storyIdBeforeDragged = currentStoryId
    }
    
    func endDraggingStoryContainer(withOffset offset: CGFloat) {
        // Imitate the close behaviour of IG story when dragging right in the first story,
        // or dragging left in the last story, close the container.
        if (currentStoryId == currentStories.first?.id && offset > 0.2) ||
            (currentStoryId == currentStories.last?.id && offset < -0.2) {
            closeStoryContainer()
        } else { // Go to previous or next.
            guard
                let currentStoryIdx =
                    currentStories.firstIndex(where: { $0.id == currentStoryId })
            else {
                return
            }
            
            let nextIdx = Int((CGFloat(currentStoryIdx) - offset).rounded())
            // Make sure within the boundary.
            currentStoryId = currentStories[min(nextIdx, stories.count - 1)].id
        }
        
        isDragging = false // End dragging.
    }
}
