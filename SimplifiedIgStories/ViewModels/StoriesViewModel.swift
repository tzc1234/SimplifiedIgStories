//
//  StoriesViewModel.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 7/3/2022.
//

import AVKit

final class StoriesViewModel: ObservableObject, StoriesHolder {
    @Published private(set) var stories: [Story] = []
    
    private let storiesLoader: StoriesLoader
    private let fileManager: FileManageable
    
    init(storiesLoader: StoriesLoader, fileManager: FileManageable) {
        self.storiesLoader = storiesLoader
        self.fileManager = fileManager
    }
}

extension StoriesViewModel {
    private var yourStoryId: Int? {
        stories.first(where: { $0.user.isCurrentUser })?.id
    }
    
    private var yourStoryIdx: Int? {
        stories.firstIndex(where: { $0.user.isCurrentUser })
    }
    
    private var lastPortionId: Int {
        stories.flatMap(\.portions).map(\.id).max() ?? -1
    }
    
    private var currentUserPortions: [Portion] {
        stories.first(where: { $0.id == yourStoryId })?.portions ?? []
    }
}

extension StoriesViewModel {
    @MainActor
    func fetchStories() async {
        do {
            let localStories = try await storiesLoader.load()
            stories = localStories.toStories()
        } catch StoriesLoaderError.notFound {
            print("JSON file not found.")
        } catch {
            print("JSON data invalid.")
        }
    }
}

// MARK: - Post/Delete Portion
// *** In real environment, the photo or video should be uploaded to server side.
// This is a demo app, however, stores them into temp directory.
extension StoriesViewModel {
    func postStoryPortion(image: UIImage) {
        guard let yourStoryIdx,
              let imageURL = try? fileManager.saveImage(image, fileName: "img_\(UUID().uuidString)") else {
            return
        }

        var portions = stories[yourStoryIdx].portions
        // Just append a new Portion instance to current user's potion array.
        portions.append(
            Portion(id: lastPortionId+1, duration: .defaultStoryDuration, resourceURL: imageURL, type: .image)
        )
        stories[yourStoryIdx].portions = portions
        stories[yourStoryIdx].lastUpdate = .now
    }
    
    func postStoryPortion(videoUrl: URL) {
        guard let yourStoryIdx else { return }

        var portions = stories[yourStoryIdx].portions
        let asset = AVAsset(url: videoUrl)
        let duration = asset.duration
        let durationSeconds = CMTimeGetSeconds(duration)

        // Similar to image case.
        portions.append(Portion(id: lastPortionId+1, duration: durationSeconds, resourceURL: videoUrl, type: .video))
        stories[yourStoryIdx].portions = portions
        stories[yourStoryIdx].lastUpdate = .now
    }
    
    func deletePortion(for portionId: Int, afterDeletion: () -> Void, noNextPortionAfterDeletion: () -> Void) {
        guard let portionIndex = currentUserPortions.firstIndex(where: { $0.id == portionId }) else { return }
        
        let hasNextPortion = portionIndex+1 < currentUserPortions.count
        removePortionInStories(at: portionIndex)
        
        if hasNextPortion {
            afterDeletion()
        } else {
            noNextPortionAfterDeletion()
        }
    }
    
    private func removePortionInStories(at portionIndex: Int) {
        guard let yourStoryIdx else { return }
        
        stories[yourStoryIdx].portions.remove(at: portionIndex)
    }
}

// MARK: - Local models conversion

private extension [LocalStory] {
    func toStories() -> [Story] {
        map { local in
            Story(
                id: local.id,
                lastUpdate: local.lastUpdate,
                user: local.user.toUser(),
                portions: local.portions.toPortions()
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
