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
        let sut = makeSUT()
        
        await sut.fetchStories()
        
        let currentUserStories = sut.stories.filter { $0.user.isCurrentUser }
        XCTAssertEqual(currentUserStories.count, 1)
    }
    
    func test_currentStories_containsOnlyOneCurrentUserStoryWhenCurrentStoryIdIsCurrentUserStoryId() async throws {
        let sut = makeSUT()
        await sut.fetchStories()
        
        let currentUserStoryId = try XCTUnwrap(sut.stories.first { $0.user.isCurrentUser }?.id)
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.currentStoryId, currentUserStoryId)
        XCTAssertEqual(sut.currentStories.count, 1)
        XCTAssertEqual(sut.currentStories.first?.id, currentUserStoryId)
    }
    
    func test_currentStories_containNoCurrentUserStoryWhenCurrentStoryIdIsNonCurrentUserStoryId() async throws {
        let sut = makeSUT()
        await sut.fetchStories()
        
        let nonCurrentUserStoryId = try XCTUnwrap(sut.stories.first { !$0.user.isCurrentUser }?.id)
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertEqual(sut.currentStoryId, nonCurrentUserStoryId)
        let currentUserStoriesInCurrentStories = sut.currentStories.filter { $0.user.isCurrentUser }
        XCTAssertEqual(currentUserStoriesInCurrentStories.count, 0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> StoriesViewModel {
        let sut = StoriesViewModel(fileManager: DummyFileManager())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
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
