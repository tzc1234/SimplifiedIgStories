//
//  StoriesViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 27/04/2022.
//

import XCTest
@testable import Simple_IG_Story

class StoriesViewModelTests: XCTestCase {
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
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) async -> StoriesViewModel {
        let sut = StoriesViewModel(fileManager: DummyFileManager(), storiesLoader: StoriesLoaderStub())
        await sut.fetchStories()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private class StoriesLoaderStub: StoriesLoader {
        func load() async throws -> [LocalStory] {
            [
                LocalStory(
                    id: 0,
                    lastUpdate: nil,
                    user: LocalUser(
                        id: 0,
                        name: "CurrentUser",
                        avatarURL: nil,
                        isCurrentUser: true
                    ),
                    portions: [
                        LocalPortion(
                            id: 0,
                            resourceURL: nil,
                            duration: .defaultStoryDuration,
                            type: .image
                        )
                    ]
                ),
                LocalStory(
                    id: 1,
                    lastUpdate: .now,
                    user: LocalUser(
                        id: 1,
                        name: "User1",
                        avatarURL: nil,
                        isCurrentUser: false
                    ),
                    portions: [
                        LocalPortion(
                            id: 1,
                            resourceURL: nil,
                            duration: .defaultStoryDuration,
                            type: .image
                        )
                    ]
                )
            ]
        }
    }
    
    private class DummyFileManager: FileManageable {
        func saveImage(_ image: UIImage, fileName: String) throws -> URL {
            URL(string: "file://any-image.jpg")!
        }
        
        func getImage(for url: URL) -> UIImage? {
            nil
        }
        
        func delete(for url: URL) throws {}
    }
}
