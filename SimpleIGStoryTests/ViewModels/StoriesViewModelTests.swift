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
    func test_stories_deliversEmptyStoriesWhenNoStoriesAfterFetch() async {
        let emptyStories = [LocalStory]()
        let sut = await makeSUT(stories: emptyStories)
        
        XCTAssertTrue(sut.stories.isEmpty)
    }
    
    func test_stories_ensuresStoriesConversionCorrect() async {
        let stories = storiesForTest()
        let sut = await makeSUT(stories: stories.local)
        
        XCTAssertEqual(sut.stories, stories.model)
    }
    
    func test_fetchStories_ensuresOneCurrentUserInStories() async {
        let stories = storiesForTest().local
        let sut = await makeSUT(stories: stories)
        
        XCTAssertEqual(sut.storiesForCurrentUser.count, 1)
    }
    
    func test_postStoryImagePortion_ignoresWhenOnFileMangerError() async throws {
        let stories = storiesForTest().local
        let sut = await makeSUT(stories: stories, imageURLStub: { throw anyNSError() })
        let anyImage = UIImage.make(withColor: .red)
        let initialPortions = sut.allPortions
        
        sut.postStoryPortion(image: anyImage)
        
        XCTAssertEqual(sut.allPortions, initialPortions)
    }

    func test_postStoryImagePortion_appendsImagePortionAtCurrentUserStory() async throws {
        let stories = storiesForTest()
        let appendedImageURL = URL(string: "file://appended-image.jpg")!
        let sut = await makeSUT(stories: stories.local, imageURLStub: { appendedImageURL })
        let anyImage = UIImage.make(withColor: .red)
        
        sut.postStoryPortion(image: anyImage)
        
        let expectedPortion = Portion(
            id: lastPortionId()+1,
            duration: .defaultStoryDuration,
            resourceURL: appendedImageURL,
            type: .image
        )
        let currentUserStory = try XCTUnwrap(sut.stories.first(where: { $0.id == currentUserStoryId() }))
        let appendedPortion = try XCTUnwrap(currentUserStory.portions.last)
        XCTAssertEqual(appendedPortion, expectedPortion)
    }
    
    func test_postStoryVideoPortion_ignoresWhenNoCurrentUserStory() async {
        let noCurrentUserStories = storiesForTest().local.filter({ !$0.user.isCurrentUser })
        let sut = await makeSUT(stories: noCurrentUserStories)
        let video = videoForTest()
        
        sut.postStoryPortion(videoUrl: video.url)
        
        XCTAssertTrue(sut.allPortions.filter({ $0.videoURL == video.url }).isEmpty)
    }
    
    func test_postStoryVideoPortion_appendsVideoPortionAtCurrentUserStory() async throws {
        let stories = storiesForTest().local
        let sut = await makeSUT(stories: stories)
        let video = videoForTest()
        
        sut.postStoryPortion(videoUrl: video.url)
        
        let expectedPortion = Portion(
            id: lastPortionId()+1,
            duration: video.duration,
            resourceURL: video.url,
            type: .video
        )
        let currentUserStory = try XCTUnwrap(sut.stories.first(where: { $0.id == currentUserStoryId() }))
        let appendedPortion = try XCTUnwrap(currentUserStory.portions.last)
        XCTAssertEqual(appendedPortion, expectedPortion)
    }
    
    func test_deletePortion_ignoresWhenInvalidPortionId() async {
        let stories = storiesForTest().local
        let sut = await makeSUT(stories: stories)
        let initialPortions = sut.allPortions
        
        let invalidPortionId = 99
        sut.deletePortion(for: invalidPortionId, afterDeletion: {}, noNextPortionAfterDeletion: {})
        
        XCTAssertEqual(sut.allPortions, initialPortions)
    }
    
    func test_deletePortion_ignoresWhenValidPortionIdButNonCurrentUserStoryPortion() async {
        let nonCurrentUserStory = hasNextPortionStory(isCurrentUser: false)
        let sut = await makeSUT(stories: [nonCurrentUserStory])
        let initialPortions = sut.allPortions
        
        let validPortionId = 0
        sut.deletePortion(for: validPortionId, afterDeletion: {}, noNextPortionAfterDeletion: {})
        
        XCTAssertEqual(sut.allPortions, initialPortions)
    }
    
    func test_deletePortion_triggersAfterDeletionAfterPortionRemovedWhenNextPortionIsExisted() async {
        let stories = [hasNextPortionStory(isCurrentUser: true)]
        let sut = await makeSUT(stories: stories)
        var hasNextPortions = sut.stories[0].portions
        
        let willBeDeletedPortionId = 0
        var afterDeletionCallCount = 0
        var noNextPortionAfterDeletionCallCount = 0
        sut.deletePortion(
            for: willBeDeletedPortionId,
            afterDeletion: { afterDeletionCallCount += 1 },
            noNextPortionAfterDeletion: { noNextPortionAfterDeletionCallCount += 1 }
        )
        
        hasNextPortions.removeFirst()
        let expectedPortionsAfterDeletion = hasNextPortions
        XCTAssertEqual(sut.stories[0].portions, expectedPortionsAfterDeletion)
        XCTAssertEqual(afterDeletionCallCount, 1)
        XCTAssertEqual(noNextPortionAfterDeletionCallCount, 0)
    }
    
    func test_deletePortion_triggersNoNextPortionAfterDeletionWhenNoNextPortionIsExisted() async {
        let stories = [noNextPortionStory(isCurrentUser: true)]
        let sut = await makeSUT(stories: stories)
        
        let willBeDeletedPortionId = 0
        var afterDeletionCallCount = 0
        var noNextPortionAfterDeletionCallCount = 0
        sut.deletePortion(
            for: willBeDeletedPortionId,
            afterDeletion: { afterDeletionCallCount += 1 },
            noNextPortionAfterDeletion: { noNextPortionAfterDeletionCallCount += 1 }
        )
        
        XCTAssertEqual(sut.stories[0].portions, [])
        XCTAssertEqual(afterDeletionCallCount, 0)
        XCTAssertEqual(noNextPortionAfterDeletionCallCount, 1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(stories: [LocalStory] = [],
                         imageURLStub: @escaping () throws -> URL = { URL(string: "file://any-image.jpg")! },
                         file: StaticString = #filePath,
                         line: UInt = #line) async -> StoriesViewModel {
        let loader = StoriesLoaderStub(stories: stories)
        let fileManager = FileManagerStub(savedImageURL: imageURLStub)
        let sut = StoriesViewModel(storiesLoader: loader, fileManager: fileManager)
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
    
    private func noNextPortionStory(isCurrentUser: Bool) -> LocalStory {
        let user = makeUser(id: 0, name: "User", isCurrentUser: isCurrentUser)
        let portion = makePortion(id: 0, resourceURL: anyImageURL())
        return makeStory(id: 0, user: user, portions: [portion]).local
    }
    
    private func hasNextPortionStory(isCurrentUser: Bool) -> LocalStory {
        let user = makeUser(id: 0, name: "User", isCurrentUser: isCurrentUser)
        let portion0 = makePortion(id: 0, resourceURL: anyImageURL())
        let portion1 = makePortion(id: 1, resourceURL: anyVideoURL(), duration: 9, type: .video)
        return makeStory(id: 0, user: user, portions: [portion0, portion1]).local
    }
    
    private func storiesForTest() -> (local: [LocalStory], model: [Story]) {
        let currentUser = makeUser(id: 0, name: "Current User", isCurrentUser: true)
        let user1 = makeUser(id: 1, name: "User1")
        let user2 = makeUser(id: 2, name: "User2")
        let portion0 = makePortion(id: 0, resourceURL: anyImageURL())
        let portion1 = makePortion(id: 1, resourceURL: anyVideoURL(), duration: 9, type: .video)
        let portion2 = makePortion(id: 2)
        let portion3 = makePortion(id: 3)
        let stories = [
            makeStory(id: 0, user: currentUser, portions: [portion0, portion1]),
            makeStory(id: 1, user: user1, portions: [portion2]),
            makeStory(id: 2, user: user2, portions: [portion3]),
        ]
        return (stories.map(\.local), stories.map(\.model))
    }
    
    private func makeStory(id: Int,
                           lastUpdate: Date = .now,
                           user: (local: LocalUser, user: User),
                           portions: [(local: LocalPortion, portion: Portion)]) -> (local: LocalStory, model: Story) {
        let local = LocalStory(id: id, lastUpdate: lastUpdate, user: user.local, portions: portions.map(\.local))
        let model = Story(id: id, lastUpdate: lastUpdate, user: user.user, portions: portions.map(\.portion))
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
                          name: String = "user",
                          avatarURL: URL? = nil,
                          isCurrentUser: Bool = false) -> (local: LocalUser, user: User) {
        let local = LocalUser(id: id, name: name, avatarURL: avatarURL, isCurrentUser: isCurrentUser)
        let user = User(id: id, name: name, avatarURL: avatarURL, isCurrentUser: isCurrentUser)
        return (local, user)
    }
}

private extension StoriesViewModel {
    var storiesForCurrentUser: [Story] {
        stories.filter { $0.user.isCurrentUser }
    }
    
    var allPortions: [Portion] {
        stories.flatMap(\.portions)
    }
}
