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
        let currentUserStoryId = 0
        let stories = [makeStory(id: currentUserStoryId, portions: [makePortion(id: 0)], isCurrentUser: true)]
        let sut = makeSUT(stories: stories)
        
        XCTAssertEqual(sut.currentStoryId, -1)
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.currentStoryId, currentUserStoryId)
        XCTAssertEqual(sut.currentStories.count, 1)
        XCTAssertEqual(sut.currentStories.first?.id, currentUserStoryId)
    }
    
    func test_currentStories_containsNoCurrentUserStoriesWhenCurrentStoryIdIsNonCurrentUserStoryId() throws {
        let nonCurrentUserStoryId = 1
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: nonCurrentUserStoryId, portions: [makePortion(id: 1)])
        ]
        let sut = makeSUT(stories: stories)
        
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertEqual(sut.currentStoryId, nonCurrentUserStoryId)
        let currentUserStories = sut.currentStories.filter { $0.user.isCurrentUser }
        XCTAssertEqual(currentUserStories.count, 0)
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
        let currentUserStoryId = 0
        let nonCurrentUserStoryId1 = 1
        let nonCurrentUserStoryId2 = 2
        let stories = [
            makeStory(id: currentUserStoryId, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: nonCurrentUserStoryId1, portions: [makePortion(id: 1)]),
            makeStory(id: nonCurrentUserStoryId2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.currentStoryIndex, 0)
        
        sut.setCurrentStoryId(nonCurrentUserStoryId1)
        
        XCTAssertEqual(sut.currentStoryIndex, 0)
        
        sut.setCurrentStoryId(nonCurrentUserStoryId2)
        
        XCTAssertEqual(sut.currentStoryIndex, 1)
    }
    
    func test_firstCurrentStoryId_deliversFirstStoryIdWhenItIsNotCurrentUserStory() {
        let nonCurrentUserStoryId1 = 1
        let nonCurrentUserStoryId2 = 2
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: nonCurrentUserStoryId1, portions: [makePortion(id: 1)]),
            makeStory(id: nonCurrentUserStoryId2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        sut.setCurrentStoryId(nonCurrentUserStoryId2)
        
        XCTAssertEqual(sut.firstCurrentStoryId, nonCurrentUserStoryId1)
    }
    
    func test_firstCurrentStoryId_deliversCurrentUserStoryIdWhenItIsCurrentUserStory() {
        let currentUserStoryId = 0
        let stories = [
            makeStory(id: currentUserStoryId, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.firstCurrentStoryId, currentUserStoryId)
    }
    
    func test_lastCurrentStoryId_deliversLastStoryIdWhenItIsNotCurrentUserStory() {
        let nonCurrentUserStoryId1 = 1
        let nonCurrentUserStoryId2 = 2
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: nonCurrentUserStoryId1, portions: [makePortion(id: 1)]),
            makeStory(id: nonCurrentUserStoryId2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        sut.setCurrentStoryId(nonCurrentUserStoryId1)
        
        XCTAssertEqual(sut.lastCurrentStoryId, nonCurrentUserStoryId2)
    }
    
    func test_lastCurrentStoryId_deliversCurrentUserStoryIdWhenItIsCurrentUserStory() {
        let currentUserStoryId = 0
        let stories = [
            makeStory(id: currentUserStoryId, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertEqual(sut.lastCurrentStoryId, currentUserStoryId)
    }
    
    func test_isAtFirstStory_deliversTrueWhenCurrentStoryIsTheFirstCurrentOne() {
        let currentUserStoryId = 0
        let nonCurrentUserStoryId = 1
        let stories = [
            makeStory(id: currentUserStoryId, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: nonCurrentUserStoryId, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertTrue(sut.isAtFirstStory, "The Current user story is at the first")
        
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertTrue(sut.isAtFirstStory, "The 1st non-current user story is at the first")
    }
    
    func test_isAtFirstStory_deliversFalseWhenCurrentStoryIsNotTheFirstCurrentOne() {
        let nonCurrentUserStoryId = 2
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: nonCurrentUserStoryId, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertFalse(sut.isAtFirstStory)
    }
    
    func test_isAtLastStory_deliversTrueWhenCurrentStoryIsTheLastCurrentOne() {
        let currentUserStoryId = 0
        let nonCurrentUserStoryId = 2
        let stories = [
            makeStory(id: currentUserStoryId, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1)]),
            makeStory(id: nonCurrentUserStoryId, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        sut.setCurrentStoryId(currentUserStoryId)
        
        XCTAssertTrue(sut.isAtLastStory, "The Current user story is at the last")
        
        sut.setCurrentStoryId(nonCurrentUserStoryId)
        
        XCTAssertTrue(sut.isAtLastStory, "The 2nd non-current user story is at the last")
    }
    
    func test_isAtLastStory_deliversFalseWhenCurrentStoryIsNotTheLastCurrentOne() {
        let nonCurrentUserStoryId = 1
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: nonCurrentUserStoryId, portions: [makePortion(id: 1)]),
            makeStory(id: 2, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
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
        let previousStoryId = 1
        let hasPreviousStoryId = 2
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: previousStoryId, portions: [makePortion(id: 1)]),
            makeStory(id: hasPreviousStoryId, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        sut.setCurrentStoryId(hasPreviousStoryId)
        sut.moveToPreviousStory()
        
        XCTAssertEqual(sut.currentStoryId, previousStoryId, "Moves to previous story after moveToPreviousStory called")
        
        sut.moveToPreviousStory()
        
        XCTAssertEqual(sut.currentStoryId, previousStoryId, "Ignores when no previous story (exclude current user story)")
    }
    
    func test_moveToNextStory_setsToCorrectStoryId() {
        let hasNextStoryId = 1
        let nextStoryId = 2
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: hasNextStoryId, portions: [makePortion(id: 1)]),
            makeStory(id: nextStoryId, portions: [makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        sut.setCurrentStoryId(hasNextStoryId)
        sut.moveToNextStory()
        
        XCTAssertEqual(sut.currentStoryId, nextStoryId, "Moves to next story after moveToNextStory called")
        
        sut.moveToNextStory()
        
        XCTAssertEqual(sut.currentStoryId, nextStoryId, "Ignores when no next story")
    }
    
    func test_getPortionCount_deliversZeroWithInvalidStoryId() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)], isCurrentUser: true),
            makeStory(id: 1, portions: [makePortion(id: 1), makePortion(id: 2)])
        ]
        let sut = makeSUT(stories: stories)
        
        let invalidStoryId = 999
        let receivedPortionCount = sut.getPortionCount(by: invalidStoryId)
        
        XCTAssertEqual(receivedPortionCount, 0)
    }
    
    func test_getPortionCount_deliversPortionCountCorrectly() {
        let firstStoryId = 0
        let secondStoryId = 1
        let firstStoryPortions = [makePortion(id: 0)]
        let secondStoryPortions = [makePortion(id: 1), makePortion(id: 2)]
        let stories = [
            makeStory(id: firstStoryId, portions: firstStoryPortions, isCurrentUser: true),
            makeStory(id: secondStoryId, portions: secondStoryPortions)
        ]
        let sut = makeSUT(stories: stories)
        
        let firstReceivedPortionCount = sut.getPortionCount(by: firstStoryId)
        
        XCTAssertEqual(firstReceivedPortionCount, firstStoryPortions.count)
        
        let secondReceivedPortionCount = sut.getPortionCount(by: secondStoryId)
        
        XCTAssertEqual(secondReceivedPortionCount, secondStoryPortions.count)
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
