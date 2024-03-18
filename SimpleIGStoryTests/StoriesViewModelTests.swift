//
//  StoriesViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 27/04/2022.
//

import XCTest
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
    
    func test_postStoryPortion_appendsImagePortionAtLast() async throws {
        let appendedImageURL = URL(string: "file://appended-image.jpg")!
        let sut = await makeSUT(imageURLStub: { appendedImageURL })
        let anyImage = UIImage.make(withColor: .red)
        let currentStoryId = 0
        sut.setCurrentStoryId(currentStoryId)
        
        sut.postStoryPortion(image: anyImage)
        
        let lastPortionId = try XCTUnwrap(storiesForTest().model.flatMap(\.portions).max(by: { $1.id > $0.id})?.id)
        let expectedPortion = Portion(
            id: lastPortionId+1,
            duration: .defaultStoryDuration,
            resourceURL: appendedImageURL,
            type: .image
        )
        let appendedPortion = try XCTUnwrap(sut.currentStories.last?.portions.last)
        XCTAssertEqual(appendedPortion, expectedPortion)
    }
    
    func test_postStoryPortion_ignoresWhenOnFileMangerError() async {
        let sut = await makeSUT(imageURLStub: { throw anyNSError() })
        let anyImage = UIImage.make(withColor: .red)
        let currentStoryId = 0
        sut.setCurrentStoryId(currentStoryId)
        
        let currentPortions = sut.currentStories.flatMap(\.portions)
        
        sut.postStoryPortion(image: anyImage)
        
        XCTAssertEqual(sut.currentStories.flatMap(\.portions), currentPortions)
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
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
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
