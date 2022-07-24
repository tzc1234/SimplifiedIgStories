//
//  StoriesViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 7/3/2022.
//

import AVKit
import UIKit

final class StoriesViewModel: ObservableObject {
    @Published var stories: [Story] = []
    
    @Published private(set) var currentStoryId = 0
    @Published var shouldCubicRotation = false
    @Published var isDragging = false
    private var storyIdBeforeDragged = 0
    
    private let dataService: DataService
    private let localFileManager: LocalFileManager
    
    init(dataService: DataService = AppDataService(), localFileManager: LocalFileManager) {
        self.dataService = dataService
        self.localFileManager = localFileManager
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
    
    // MARK: Post StoryPortion
    // *** In real environment, the photo or video should be uploaded to server side.
    // This is a demo app, however, stores them into temp directory.
    
    func postStoryPortion(image: UIImage) {
        guard let yourStoryIdx = yourStoryIdx,
              let imageUrl = localFileManager.saveImageToTemp(image: image)
        else {
            return
        }

        var portions = stories[yourStoryIdx].portions
        // Just append a new Portion instance to current user's potion array.
        portions.append(Portion(id: lastPortionId + 1, imageUrl: imageUrl))
        stories[yourStoryIdx].portions = portions
        stories[yourStoryIdx].lastUpdate = Date().timeIntervalSince1970
    }
    
    func postStoryPortion(videoUrl: URL) {
        guard let yourStoryIdx = yourStoryIdx else {
            return
        }

        var portions = stories[yourStoryIdx].portions
        let asset = AVAsset(url: videoUrl)
        let duration = asset.duration
        let durationSeconds = CMTimeGetSeconds(duration)

        // Similar to image case.
        portions.append(Portion(id: lastPortionId + 1, videoDuration: durationSeconds, videoUrlFromCam: videoUrl))
        stories[yourStoryIdx].portions = portions
        stories[yourStoryIdx].lastUpdate = Date().timeIntervalSince1970
    }
}
