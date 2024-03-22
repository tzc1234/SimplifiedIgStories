//
//  StoriesViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 27/04/2022.
//

import XCTest
import AVKit
@testable import Simple_IG_Story

class StoriesViewModelTests: XCTestCase {
//    func test_stories_deliversEmptyStoriesWhenNoStoriesAfterFetch() async {
//        let emptyStories = [LocalStory]()
//        let sut = await makeSUT(stories: emptyStories)
//        
//        XCTAssertTrue(sut.stories.isEmpty)
//    }
//    
//    func test_stories_ensuresStoriesConversionCorrect() async {
//        let stories = storiesForTest()
//        let sut = await makeSUT(stories: stories.local)
//        
//        XCTAssertEqual(sut.stories, stories.model)
//    }
//    
//    func test_fetchStories_ensuresOneCurrentUserInStories() async {
//        let sut = await makeSUT()
//        
//        let currentUserStories = sut.stories.filter { $0.user.isCurrentUser }
//        XCTAssertEqual(currentUserStories.count, 1)
//    }
//
//    func test_postStoryImagePortion_appendsImagePortionAtCurrentUserStory() async throws {
//        let appendedImageURL = URL(string: "file://appended-image.jpg")!
//        let sut = await makeSUT(imageURLStub: { appendedImageURL })
//        let anyImage = UIImage.make(withColor: .red)
//        
//        sut.postStoryPortion(image: anyImage)
//        
//        let expectedPortion = Portion(
//            id: lastPortionId()+1,
//            duration: .defaultStoryDuration,
//            resourceURL: appendedImageURL,
//            type: .image
//        )
//        let currentUserStory = try XCTUnwrap(sut.stories.first(where: { $0.id == currentUserStoryId() }))
//        let appendedPortion = try XCTUnwrap(currentUserStory.portions.last)
//        XCTAssertEqual(appendedPortion, expectedPortion)
//    }
    
//    func test_postStoryImagePortion_ignoresWhenOnFileMangerError() async {
//        let sut = await makeSUT(imageURLStub: { throw anyNSError() })
//        let anyImage = UIImage.make(withColor: .red)
//        let currentStoryId = 0
//        sut.setCurrentStoryId(currentStoryId)
//        
//        let currentPortions = sut.currentStories.flatMap(\.portions)
//        
//        sut.postStoryPortion(image: anyImage)
//        
//        XCTAssertEqual(sut.currentStories.flatMap(\.portions), currentPortions)
//    }
    
//    func test_postStoryVideoPortion_appendsVideoPortionAtCurrentUserStory() async throws {
//        let video = videoForTest()
//        let sut = await makeSUT()
//        
//        sut.postStoryPortion(videoUrl: video.url)
//        
//        let expectedPortion = Portion(
//            id: lastPortionId()+1,
//            duration: video.duration,
//            resourceURL: video.url,
//            type: .video
//        )
//        let currentUserStory = try XCTUnwrap(sut.stories.first(where: { $0.id == currentUserStoryId() }))
//        let appendedPortion = try XCTUnwrap(currentUserStory.portions.last)
//        XCTAssertEqual(appendedPortion, expectedPortion)
//    }
    
//    func test_postStoryVideoPortion_ignoresWhenNoCurrentUserStory() async {
//        let video = videoForTest()
//        let noCurrentUserStories = storiesForTest().local.filter({ !$0.user.isCurrentUser })
//        let sut = await makeSUT(stories: noCurrentUserStories)
//        
//        sut.postStoryPortion(videoUrl: video.url)
//        
//        XCTAssertTrue(sut.allPortions.filter({ $0.videoURL == video.url }).isEmpty)
//    }
    
    // MARK: - Helpers
    
    private func makeSUT(stories: [LocalStory]? = nil,
                         imageURLStub: @escaping () throws -> URL = {URL(string: "file://any-image.jpg")! },
                         file: StaticString = #filePath,
                         line: UInt = #line) async -> StoriesViewModel {
        let loader = StoriesLoaderStub(stories: stories == nil ? storiesForTest().local : stories!)
        let fileManager = FileManagerStub(savedImageURL: imageURLStub)
        let sut = StoriesViewModel(storiesLoader: loader, fileManager: fileManager, mediaSaver: DummyMediaSaver())
        await sut.fetchStories()
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(fileManager, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func videoForTest() -> (url: URL, duration: Double) {
        let videoURL = Bundle.main.url(forResource: "seaVideo", withExtension: "mp4")!
        let duration = CMTimeGetSeconds(AVAsset(url: videoURL).duration)
        return (videoURL, duration)
    }
    
    private func currentUserStoryId() -> Int {
        storiesForTest().model.first(where: { $0.user.isCurrentUser })!.id
    }
    
    private func lastPortionId() -> Int {
        storiesForTest().model.flatMap(\.portions).max(by: { $1.id > $0.id})!.id
    }
    
    private func storiesForTest() -> (local: [LocalStory], model: [Story]) {
        let currentUser = makeUser(id: 0, name: "Current User", isCurrentUser: true)
        let user1 = makeUser(id: 1, name: "User1")
        let user2 = makeUser(id: 2, name: "User2")
        let portion0 = makePortion(id: 0, resourceURL: anyImageURL())
        let portion1 = makePortion(id: 1, resourceURL: anyVideoURL(), duration: 9, type: .video)
        let portion2 = makePortion(id: 2)
        let portion3 = makePortion(id: 3)
        let now = Date.now
        
        let local = [
            LocalStory(
                id: 0,
                lastUpdate: nil,
                user: currentUser.local,
                portions: [portion0.local, portion1.local]
            ),
            LocalStory(
                id: 1,
                lastUpdate: now,
                user: user1.local,
                portions: [portion2.local]
            ),
            LocalStory(
                id: 2,
                lastUpdate: now.addingTimeInterval(1),
                user: user2.local,
                portions: [portion3.local]
            )
        ]
        let model = [
            Story(
                id: 0,
                lastUpdate: nil,
                user: currentUser.user,
                portions: [portion0.portion, portion1.portion]
            ),
            Story(
                id: 1,
                lastUpdate: now,
                user: user1.user,
                portions: [portion2.portion]
            ),
            Story(
                id: 2,
                lastUpdate: now.addingTimeInterval(1),
                user: user2.user,
                portions: [portion3.portion]
            )
        ]
        
        return (local, model)
    }
    
    private func makePortion(id: Int,
                             resourceURL: URL? = nil,
                             duration: Double = .defaultStoryDuration,
                             type: LocalResourceType = .image) -> (local: LocalPortion, portion: Portion) {
        let local = LocalPortion(id: id, resourceURL: resourceURL, duration: duration, type: type)
        let portion = Portion(
            id: id,
            duration: duration,
            resourceURL: resourceURL,
            type: .init(rawValue: type.rawValue) ?? .image
        )
        return (local, portion)
    }
    
    private func makeUser(id: Int,
                          name: String,
                          avatarURL: URL? = nil,
                          isCurrentUser: Bool = false) -> (local: LocalUser, user: User) {
        let local = LocalUser(id: id, name: name, avatarURL: avatarURL, isCurrentUser: isCurrentUser)
        let user = User(id: id, name: name, avatarURL: avatarURL, isCurrentUser: isCurrentUser)
        return (local, user)
    }
    
    private class StoriesLoaderStub: StoriesLoader {
        private let stories: [LocalStory]
        
        init(stories: [LocalStory]) {
            self.stories = stories
        }
        
        func load() async throws -> [LocalStory] {
            stories
        }
    }
    
    private class FileManagerStub: FileManageable {
        private let savedImageURL: () throws -> URL
        
        init(savedImageURL: @escaping () throws -> URL) {
            self.savedImageURL = savedImageURL
        }
        
        func saveImage(_ image: UIImage, fileName: String) throws -> URL {
            try savedImageURL()
        }
        
        func getImage(for url: URL) -> UIImage? {
            nil
        }
        
        func delete(for url: URL) throws {}
    }
    
    private class DummyMediaSaver: MediaSaver {
        func saveImageData(_ data: Data) async throws {}
        func saveVideo(by url: URL) async throws {}
    }
}

//extension StoriesViewModel {
//    var allPortions: [Portion] {
//        stories.flatMap(\.portions)
//    }
//}
