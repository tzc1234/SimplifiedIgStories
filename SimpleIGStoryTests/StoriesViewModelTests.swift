//
//  StoriesViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 27/04/2022.
//

import XCTest
@testable import Simple_IG_Story

class StoriesViewModelTests: XCTestCase {
    
    var sut: StoriesViewModel!
    
    override func setUpWithError() throws {
        sut = StoriesViewModel(fileManager: LocalFileManager())
        
        let expectation = XCTestExpectation(description: "wait async fetchStories")
        
        Task {
            await sut.fetchStories()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.5)
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func test_stories_ensureOneCurrentUserInStories() {
        let stories = sut.stories
        let currentUserStory = stories.first(where: { $0.user.isCurrentUser })
        let currentUserStoryIdx = stories.firstIndex(where: { $0.user.isCurrentUser })
        
        XCTAssertNotNil(currentUserStory, "currentUserStory")
        XCTAssertNotNil(currentUserStoryIdx, "currentUserStoryIdx")
    }
    
    func test_currentStories_shouldContainOnlyOneCurrentUserStory_whenCurrentStoryIdIsSetToCurrentUserStoryId() throws {
        let currentUserStoryId = try XCTUnwrap(sut.stories.first(where: { $0.user.isCurrentUser })?.id)
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.currentStoryId, currentUserStoryId, "currentStoryId == currentUserStoryId")
        XCTAssertEqual(sut.currentStories.count, 1, "currentStories.count == 1")
        XCTAssertEqual(sut.currentStories.first?.id, currentUserStoryId, "currentStories.first.id == currentUserStoryId")
    }
    
    func test_currentStories_shouldNotContainCurrentUserStory_whenCurrentStoryIdIsNotCurrentUserStoryId() throws {
        let nonCurrentUserStoryId = try XCTUnwrap(sut.stories.first(where: { !$0.user.isCurrentUser })?.id)
        
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertEqual(sut.currentStoryId, nonCurrentUserStoryId, "currentStoryId == nonCurrentUserStoryId")
        XCTAssertEqual(sut.currentStories.filter { $0.user.isCurrentUser }.count, 0, "currentStories")
    }
    
}
