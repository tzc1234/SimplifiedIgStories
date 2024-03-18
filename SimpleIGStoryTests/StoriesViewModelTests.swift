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
        let sut = await makeSUT()
        
        let currentUserStories = sut.stories.filter { $0.user.isCurrentUser }
        XCTAssertEqual(currentUserStories.count, 1)
    }
    
    func test_currentStories_containsOnlyOneCurrentUserStoryWhenCurrentStoryIdIsCurrentUserStoryId() async throws {
        let sut = await makeSUT()
        
        let currentUserStoryId = try XCTUnwrap(sut.stories.first { $0.user.isCurrentUser }?.id)
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.currentStoryId, currentUserStoryId)
        XCTAssertEqual(sut.currentStories.count, 1)
        XCTAssertEqual(sut.currentStories.first?.id, currentUserStoryId)
    }
    
    func test_currentStories_containNoCurrentUserStoryWhenCurrentStoryIdIsNonCurrentUserStoryId() async throws {
        let sut = await makeSUT()
        
        let nonCurrentUserStoryId = try XCTUnwrap(sut.stories.first { !$0.user.isCurrentUser }?.id)
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertEqual(sut.currentStoryId, nonCurrentUserStoryId)
        let currentUserStoriesInCurrentStories = sut.currentStories.filter { $0.user.isCurrentUser }
        XCTAssertEqual(currentUserStoriesInCurrentStories.count, 0)
    }
    
    func test_saveStoryIdBeforeDragged_savesCurrentStoryId() async {
        let sut = await makeSUT()
        
        XCTAssertFalse(sut.isSameStoryAfterDragging)
        
        sut.saveStoryIdBeforeDragged()
        
        XCTAssertTrue(sut.isSameStoryAfterDragging)
    }
    
    func test_setCurrentStoryId_ignoresWhenStoryIdIsNotExisted() async {
        let sut = await makeSUT()
        let storyIdNotExisted = 99
        let initialCurrentStoryId = sut.currentStoryId
        
        sut.setCurrentStoryId(storyIdNotExisted)
        
        XCTAssertEqual(sut.currentStoryId, initialCurrentStoryId)
    }
    
    func test_firstCurrentStoryId_deliversFirstStoryIdWhenItIsNotCurrentUserStory() async {
        let sut = await makeSUT()
        let notCurrentUserStoryId = 2
        
        sut.setCurrentStoryId(notCurrentUserStoryId)
        
        XCTAssertEqual(sut.firstCurrentStoryId, 1)
    }
    
    func test_firstCurrentStoryId_deliversCurrentUserStoryIdWhenItIsCurrentUserStory() async {
        let sut = await makeSUT()
        let currentUserStoryId = 0
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.firstCurrentStoryId, currentUserStoryId)
    }
    
    func test_lastCurrentStoryId_deliversLastStoryIdWhenItIsNotCurrentUserStory() async {
        let sut = await makeSUT()
        let notCurrentUserStoryId = 1
        
        sut.setCurrentStoryId(notCurrentUserStoryId)
        
        XCTAssertEqual(sut.lastCurrentStoryId, 2)
    }
    
    func test_lastCurrentStoryId_deliversCurrentUserStoryIdWhenItIsCurrentUserStory() async {
        let sut = await makeSUT()
        let currentUserStoryId = 0
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.lastCurrentStoryId, currentUserStoryId)
    }
    
    func test_isAtFirstStory_deliversTrueWhenCurrentStoryIsTheFirstCurrentOne() async {
        let sut = await makeSUT()
        let currentUserStoryId = 0
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertTrue(sut.isAtFirstStory, "The Current user story is at the first")
        
        let notCurrentUserStoryId = 1
        sut.setCurrentStoryId(notCurrentUserStoryId)
        
        XCTAssertTrue(sut.isAtFirstStory, "The 1st non-current user story is at the first")
    }
    
    func test_isAtFirstStory_deliversFalseWhenCurrentStoryIsNotTheFirstCurrentOne() async {
        let sut = await makeSUT()
        
        let notCurrentUserStoryId = 2
        sut.setCurrentStoryId(notCurrentUserStoryId)
        
        XCTAssertFalse(sut.isAtFirstStory)
    }
    
    func test_isAtLastStory_deliversTrueWhenCurrentStoryIsTheLastCurrentOne() async {
        let sut = await makeSUT()
        let currentUserStoryId = 0
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertTrue(sut.isAtLastStory, "The Current user story is at the last")
        
        let notCurrentUserStoryId = 2
        sut.setCurrentStoryId(notCurrentUserStoryId)
        
        XCTAssertTrue(sut.isAtLastStory, "The 2nd non-current user story is at the last")
    }
    
    func test_isAtLastStory_deliversFalseWhenCurrentStoryIsNotTheLastCurrentOne() async {
        let sut = await makeSUT()
        
        let notCurrentUserStoryId = 1
        sut.setCurrentStoryId(notCurrentUserStoryId)
        
        XCTAssertFalse(sut.isAtLastStory)
    }
    
    func test_getIsDraggingPublisher_deliversIsDraggingProperly() async {
        let sut = await makeSUT()
        var loggedIsDragging = [Bool]()
        let cancellable = sut.getIsDraggingPublisher().sink { loggedIsDragging.append($0) }
        
        XCTAssertEqual(loggedIsDragging, [false])
        
        sut.isDragging = true
        
        XCTAssertEqual(loggedIsDragging, [false, true])
        
        sut.isDragging = false
        
        XCTAssertEqual(loggedIsDragging, [false, true, false])
    }
    
    func test_getStory_deliversNoStoryWhenStoryNotFound() async {
        let sut = await makeSUT()
        let notFoundStoryId = 99
        
        let receivedStory = sut.getStory(by: notFoundStoryId)
        
        XCTAssertNil(receivedStory)
    }
    
    func test_getStory_deliversCorrectStoryByStoryId() async {
        let sut = await makeSUT()
        let storyId = 1
        
        let receivedStory = sut.getStory(by: storyId)
        
        XCTAssertEqual(receivedStory?.id, storyId)
    }
    
    func test_moveToPreviousStory_setsToCorrectStoryId() async {
        let sut = await makeSUT()
        let hasPreviousStoryId = 2
        sut.setCurrentStoryId(hasPreviousStoryId)
        
        sut.moveToPreviousStory()
        
        XCTAssertEqual(sut.currentStoryId, 1, "Moves to previous story after moveToPreviousStory called")
        
        sut.moveToPreviousStory()
        
        XCTAssertEqual(sut.currentStoryId, 1, "Ignores when no previous story (exclude current user story)")
    }
    
    func test_moveToNextStory_setsToCorrectStoryId() async {
        let sut = await makeSUT()
        let hasNextStoryId = 1
        sut.setCurrentStoryId(hasNextStoryId)
        
        sut.moveToNextStory()
        
        XCTAssertEqual(sut.currentStoryId, 2, "Moves to next story after moveToNextStory called")
        
        sut.moveToNextStory()
        
        XCTAssertEqual(sut.currentStoryId, 2, "Ignores when no next story")
    }
    
    func test_postStoryImagePortion_appendsImagePortionAtCurrentUserStory() async throws {
        let appendedImageURL = URL(string: "file://appended-image.jpg")!
        let sut = await makeSUT(imageURLStub: { appendedImageURL })
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
    
    func test_postStoryImagePortion_ignoresWhenOnFileMangerError() async {
        let sut = await makeSUT(imageURLStub: { throw anyNSError() })
        let anyImage = UIImage.make(withColor: .red)
        let currentStoryId = 0
        sut.setCurrentStoryId(currentStoryId)
        
        let currentPortions = sut.currentStories.flatMap(\.portions)
        
        sut.postStoryPortion(image: anyImage)
        
        XCTAssertEqual(sut.currentStories.flatMap(\.portions), currentPortions)
    }
    
    func test_postStoryVideoPortion_appendsVideoPortionAtCurrentUserStory() async throws {
        let video = videoForTest()
        let sut = await makeSUT()
        
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
    
    func test_postStoryVideoPortion_ignoresWhenNoCurrentUserStory() async {
        let video = videoForTest()
        let noCurrentUserStories = storiesForTest().local.filter({ !$0.user.isCurrentUser })
        let sut = await makeSUT(stories: noCurrentUserStories)
        
        sut.postStoryPortion(videoUrl: video.url)
        
        let portions = sut.stories.flatMap(\.portions)
        XCTAssertTrue(portions.filter({ $0.videoURL == video.url }).isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(stories: [LocalStory]? = nil,
                         imageURLStub: @escaping () throws -> URL = {URL(string: "file://any-image.jpg")! },
                         file: StaticString = #filePath,
                         line: UInt = #line) async -> StoriesViewModel {
        let loader = StoriesLoaderStub(stories: stories == nil ? storiesForTest().local : stories!)
        let fileManager = FileManagerStub(savedImageURL: imageURLStub)
        let sut = StoriesViewModel(fileManager: fileManager, storiesLoader: loader)
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
}
