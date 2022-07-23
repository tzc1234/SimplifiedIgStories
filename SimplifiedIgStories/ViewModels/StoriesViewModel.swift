//
//  StoriesViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 7/3/2022.
//

import Foundation

final class StoriesViewModel: ObservableObject {
    @Published var stories: [Story] = []
    
    @Published private(set) var currentStoryId = 0
    @Published var shouldCubicRotation = false
    @Published var isDragging = false
    private var storyIdBeforeDragged = 0
    
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
    
    var isSameStoryAfterDragged: Bool {
        currentStoryId == storyIdBeforeDragged
    }
    
    var currentStoryIndex: Int? {
        currentStories.firstIndex(where: { $0.id == currentStoryId })
    }
    
    var isNowAtFirstStory: Bool {
        currentStoryId == currentStories.first?.id
    }
    
    var isNowAtLastStory: Bool {
        currentStoryId == currentStories.last?.id
    }
}

// MARK: internal functions
extension StoriesViewModel {
    @MainActor func fetchStories() async {
        do {
            self.stories = try await dataService.fetchStories()
        } catch {
            let errMsg = (error as? DataServiceError)?.errMsg ?? error.localizedDescription
            print(errMsg)
        }
    }
    
    func updateStoryIdBeforeDragged() {
        storyIdBeforeDragged = currentStoryId
    }
    
    func setCurrentStoryId(_ storyId: Int) {
        guard stories.map(\.id).contains(storyId) else {
            return
        }
        currentStoryId = storyId
    }
    
    func getStoryById(_ storyId: Int) -> Story? {
        stories.first(where: { $0.id == storyId })
    }
}
