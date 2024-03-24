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
    
    func test_getIsDraggingPublisher_deliversIsDraggingProperly() {
        let sut = makeSUT()
        var loggedIsDragging = [Bool]()
        let cancellable = sut.getIsDraggingPublisher().sink { loggedIsDragging.append($0) }
        
        XCTAssertEqual(loggedIsDragging, [false])
        
        sut.isDragging = true
        
        XCTAssertEqual(loggedIsDragging, [false, true])
        
        sut.isDragging = false
        
        XCTAssertEqual(loggedIsDragging, [false, true, false])
        
        cancellable.cancel()
    }
    
    func test_moveToPreviousStory_setsToCorrectStoryId() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        let hasPreviousStoryId = 2
        sut.setCurrentStoryId(hasPreviousStoryId)
        
        sut.moveToPreviousStory()
        
        XCTAssertEqual(sut.currentStoryId, 1, "Moves to previous story after moveToPreviousStory called")
        
        sut.moveToPreviousStory()
        
        XCTAssertEqual(sut.currentStoryId, 1, "Ignores when no previous story (exclude current user story)")
    }
    
    func test_moveToNextStory_setsToCorrectStoryId() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        let hasNextStoryId = 1
        sut.setCurrentStoryId(hasNextStoryId)
        
        sut.moveToNextStory()
        
        XCTAssertEqual(sut.currentStoryId, 2, "Moves to next story after moveToNextStory called")
        
        sut.moveToNextStory()
        
        XCTAssertEqual(sut.currentStoryId, 2, "Ignores when no next story")
    }
    
    func test_getPortionCount_deliversZeroWithInvalidStoryId() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1), makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        let receivedPortionCount = sut.getPortionCount(by: 2)
        
        XCTAssertEqual(receivedPortionCount, 0)
    }
    
    func test_getPortionCount_deliversPortionCountCorrectly() {
        let expectedPortions0 = [makePortion(id: 0)]
        let expectedPortions1 = [makePortion(id: 1), makePortion(id: 2)]
        let stories = [
            makeStory(id: 0, portions: expectedPortions0, isCurrentUser: true),
            makeStory(id: 1, portions: expectedPortions1)
        ]
        let sut = makeSUT(stories: stories)
        
        let receivedPortionCount0 = sut.getPortionCount(by: 0)
        
        XCTAssertEqual(receivedPortionCount0, expectedPortions0.count)
        
        let receivedPortionCount1 = sut.getPortionCount(by: 1)
        
        XCTAssertEqual(receivedPortionCount1, expectedPortions1.count)
    }
    
    func test_subscribeObjectWillChange_triggersSelfObjectWillChangeWhenStoriesHolderObjectWillChangeGetTriggered() {
        let storiesHolder = StoriesHolderStub(stories: [])
        let sut = StoriesAnimationHandler(storiesHolder: storiesHolder)
        var objectWillChangeCount = 0
        let cancellable = sut.objectWillChange.sink { _ in objectWillChangeCount += 1 }
        
        XCTAssertEqual(objectWillChangeCount, 0)
        
        storiesHolder.objectWillChange.send()
        
        XCTAssertEqual(objectWillChangeCount, 1)
        
        cancellable.cancel()
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
