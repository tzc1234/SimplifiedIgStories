//
//  StoriesAnimationHandlerTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 22/03/2024.
//

import XCTest
@testable import Simple_IG_Story

final class StoriesAnimationHandlerTests: XCTestCase {
    func test_init_deliversStoriesAsStoriesHolderStories() {
        let stories = [makeStory(portions: [makePortion(id: 0)])]
        let sut = makeSUT(stories: stories)
        
        XCTAssertEqual(sut.stories, stories)
    }
    
    func test_currentStories_containsOnlyOneCurrentUserStoryWhenCurrentStoryIdIsCurrentUserStoryId() throws {
        let stories = [makeStory(portions: [makePortion(id: 0)], isCurrentUser: true)]
        let sut = makeSUT(stories: stories)
        
        let currentUserStoryId = try XCTUnwrap(sut.stories.first { $0.user.isCurrentUser }?.id)
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.currentStoryId, currentUserStoryId)
        XCTAssertEqual(sut.currentStories.count, 1)
        XCTAssertEqual(sut.currentStories.first?.id, currentUserStoryId)
    }
    
    func test_currentStories_containsNoCurrentUserStoryWhenCurrentStoryIdIsNonCurrentUserStoryId() throws {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)])
        ]
        let sut = makeSUT(stories: stories)
        
        let nonCurrentUserStoryId = try XCTUnwrap(sut.stories.first { !$0.user.isCurrentUser }?.id)
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertEqual(sut.currentStoryId, nonCurrentUserStoryId)
        let currentUserStoriesInCurrentStories = sut.currentStories.filter { $0.user.isCurrentUser }
        XCTAssertEqual(currentUserStoriesInCurrentStories.count, 0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(stories: [Story] = [], 
                         file: StaticString = #filePath,
                         line: UInt = #line) -> StoriesAnimationHandler {
        let storiesHolder = StoriesHolderStub(stories: stories)
        let sut = StoriesAnimationHandler(storiesHolder: storiesHolder)
        trackForMemoryLeaks(storiesHolder, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private class StoriesHolderStub: ObservableObject, StoriesHolder {
        private let stub: [Story]
        
        init(stories: [Story]) {
            self.stub = stories
        }
        
        var stories: [Story] {
            stub
        }
    }
}
