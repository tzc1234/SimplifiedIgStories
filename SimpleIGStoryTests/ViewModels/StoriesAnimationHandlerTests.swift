//
//  StoriesAnimationHandlerTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 22/03/2024.
//

import XCTest
@testable import Simple_IG_Story

final class StoriesAnimationHandlerTests: XCTestCase {
    func test_init_deliversEmptyStoriesWhenNoStoriesHolderStories() {
        let emptyStories = [Story]()
        let sut = makeSUT(stories: emptyStories)
        
        XCTAssertEqual(sut.stories, emptyStories)
    }
    
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
    
    func test_saveStoryIdBeforeDragged_savesCurrentStoryId() {
        let sut = makeSUT()
        
        XCTAssertFalse(sut.isSameStoryAfterDragging)
        
        sut.saveStoryIdBeforeDragged()
        
        XCTAssertTrue(sut.isSameStoryAfterDragging)
    }
    
    func test_setCurrentStoryId_ignoresWhenStoryIdIsNotExisted() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let sut = makeSUT(stories: stories)
        let initialCurrentStoryId = sut.currentStoryId
        let storyIdNotExisted = 99
        
        sut.setCurrentStoryId(storyIdNotExisted)
        
        XCTAssertEqual(sut.currentStoryId, initialCurrentStoryId)
    }
    
    func test_currentStoryIndex_deliversStoryIndexCorrectly() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        let currentUserStoryId = 0
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.currentStoryIndex, 0)
        
        let nonCurrentUserStoryId1 = 1
        sut.setCurrentStoryId(nonCurrentUserStoryId1)
        
        XCTAssertEqual(sut.currentStoryIndex, 0)
        
        let nonCurrentUserStoryId2 = 2
        sut.setCurrentStoryId(nonCurrentUserStoryId2)
        
        XCTAssertEqual(sut.currentStoryIndex, 1)
    }
    
    func test_firstCurrentStoryId_deliversFirstStoryIdWhenItIsNotCurrentUserStory() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        let nonCurrentUserStoryId = 2
        
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertEqual(sut.firstCurrentStoryId, 1)
    }
    
    func test_firstCurrentStoryId_deliversCurrentUserStoryIdWhenItIsCurrentUserStory() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        let currentUserStoryId = 0
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.firstCurrentStoryId, currentUserStoryId)
    }
    
    func test_lastCurrentStoryId_deliversLastStoryIdWhenItIsNotCurrentUserStory() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        let nonCurrentUserStoryId = 1
        
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertEqual(sut.lastCurrentStoryId, 2)
    }
    
    func test_lastCurrentStoryId_deliversCurrentUserStoryIdWhenItIsCurrentUserStory() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        let currentUserStoryId = 0
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.lastCurrentStoryId, currentUserStoryId)
    }
    
    func test_isAtFirstStory_deliversTrueWhenCurrentStoryIsTheFirstCurrentOne() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        let currentUserStoryId = 0
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertTrue(sut.isAtFirstStory, "The Current user story is at the first")
        
        let nonCurrentUserStoryId = 1
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertTrue(sut.isAtFirstStory, "The 1st non-current user story is at the first")
    }
    
    func test_isAtFirstStory_deliversFalseWhenCurrentStoryIsNotTheFirstCurrentOne() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        let nonCurrentUserStoryId = 2
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertFalse(sut.isAtFirstStory)
    }
    
    func test_isAtLastStory_deliversTrueWhenCurrentStoryIsTheLastCurrentOne() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        let currentUserStoryId = 0
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertTrue(sut.isAtLastStory, "The Current user story is at the last")
        
        let nonCurrentUserStoryId = 2
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertTrue(sut.isAtLastStory, "The 2nd non-current user story is at the last")
    }
    
    func test_isAtLastStory_deliversFalseWhenCurrentStoryIsNotTheLastCurrentOne() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        let nonCurrentUserStoryId = 1
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertFalse(sut.isAtLastStory)
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
