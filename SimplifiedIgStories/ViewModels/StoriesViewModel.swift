//
//  StoriesViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 7/3/2022.
//

import AVKit
import UIKit
import Combine

enum StoryMoveDirection {
    case previous, next
}

final class StoriesViewModel: ObservableObject, ParentStoryViewModel {
    @Published var stories: [Story] = []
    
    @Published private(set) var currentStoryId = -1
    @Published var shouldCubicRotation = false
    @Published var isDragging = false
    private(set) var storyIdBeforeDragged = 0
    
    private let storiesLoader: StoriesLoader?
    private let fileManager: ImageFileManageable
    
    init(fileManager: ImageFileManageable) {
        self.fileManager = fileManager
        
        guard let url = Bundle.main.url(forResource: "storiesData.json", withExtension: nil) else {
            self.storiesLoader = nil
            return
        }
        
        let dataClient = FileDataClient(url: url)
        self.storiesLoader = LocalStoriesLoader(client: dataClient)
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
    
    private var lastPortionId: Int {
        currentStories.flatMap(\.portions).map(\.id).max() ?? -1
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
    
    var isNowAtFirstStory: Bool {
        currentStoryId == firstCurrentStoryId
    }
    
    var isAtLastStory: Bool {
        currentStoryId == lastCurrentStoryId
    }
}

// MARK: internal functions
extension StoriesViewModel {
    func getIsDraggingPublisher() -> AnyPublisher<Bool, Never> {
        $isDragging.eraseToAnyPublisher()
    }
    
    @MainActor
    func fetchStories() async {
        do {
            guard let localStories = try await storiesLoader?.load() else {
                return
            }
            
            stories = localStories.toStories()
        } catch StoriesLoaderError.notFound {
            print("JSON file not found.")
        } catch {
            print("JSON data invalid.")
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
    
    func moveCurrentStory(to direction: StoryMoveDirection) {
        guard let currentStoryIndex else {
            return
        }
        
        switch direction {
        case .previous:
            if currentStoryIndex - 1 >= 0 {
                currentStoryId = currentStories[currentStoryIndex - 1].id
            }
        case .next:
            if currentStoryIndex + 1 < currentStories.count {
                currentStoryId = currentStories[currentStoryIndex + 1].id
            }
        }
    }
    
    func getStory(by storyId: Int) -> Story? {
        stories.first(where: { $0.id == storyId })
    }
    
    // MARK: Post StoryPortion
    // *** In real environment, the photo or video should be uploaded to server side.
    // This is a demo app, however, stores them into temp directory.
    
    func postStoryPortion(image: UIImage) {
        guard let yourStoryIdx = yourStoryIdx,
              let imageURL = try? fileManager.saveImage(image, fileName: "img_\(UUID().uuidString)") else {
            return
        }

        var portions = stories[yourStoryIdx].portions
        // Just append a new Portion instance to current user's potion array.
        portions.append(Portion(id: lastPortionId+1, duration: .defaultStoryDuration, resourceURL: imageURL, type: .image))
        stories[yourStoryIdx].portions = portions
        stories[yourStoryIdx].lastUpdate = .now
    }
    
    func postStoryPortion(videoUrl: URL) {
        guard let yourStoryIdx else {
            return
        }

        var portions = stories[yourStoryIdx].portions
        let asset = AVAsset(url: videoUrl)
        let duration = asset.duration
        let durationSeconds = CMTimeGetSeconds(duration)

        // Similar to image case.
        portions.append(Portion(id: lastPortionId+1, duration: durationSeconds, resourceURL: videoUrl, type: .video))
        stories[yourStoryIdx].portions = portions
        stories[yourStoryIdx].lastUpdate = .now
    }
}

private extension [LocalStory] {
    func toStories() -> [Story] {
        map { local in
            Story(
                id: local.id,
                lastUpdate: local.lastUpdate,
                portions: local.portions.toPortions(),
                user: local.user.toUser()
            )
        }
    }
}

private extension [LocalPortion] {
    func toPortions() -> [Portion] {
        map { local in
            switch local.type {
            case .image:
                return Portion(
                    id: local.id, 
                    duration: local.duration,
                    resourceURL: local.resourceURL,
                    type: .init(rawValue: local.type.rawValue) ?? .image
                )
            case .video:
                return Portion(
                    id: local.id, 
                    duration: local.duration,
                    resourceURL: local.resourceURL,
                    type: .init(rawValue: local.type.rawValue) ?? .image
                )
            }
        }
    }
}

private extension LocalUser {
    func toUser() -> User {
        User(id: id, name: name, avatarURL: avatarURL, isCurrentUser: isCurrentUser)
    }
}
