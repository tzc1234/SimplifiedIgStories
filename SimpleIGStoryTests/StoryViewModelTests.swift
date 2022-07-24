//
//  StoryViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 24/07/2022.
//

import XCTest
import Combine
@testable import Simple_IG_Story

class StoryViewModelTests: XCTestCase {
    
    var sut: StoryViewModel!
    
    override func setUpWithError() throws {
        let storiesViewModel = StoriesViewModel(fileManager: LocalFileManager())
        
        let expectation = XCTestExpectation(description: "wait async fetchStories")
        Task {
            await storiesViewModel.fetchStories()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.3)
        
        let firstHasPortionStory = storiesViewModel.stories.filter { $0.hasPortion }.first
        XCTAssertNotNil(firstHasPortionStory, "firstHasPortionStory")
        
        storiesViewModel.setCurrentStoryId(firstHasPortionStory!.id)
        
        XCTAssertEqual(storiesViewModel.currentStoryId, firstHasPortionStory!.id, "currentStoryId")
        
        let fileManager = LocalFileManager()
        sut = StoryViewModel(storyId: firstHasPortionStory!.id, storiesViewModel: storiesViewModel, fileManager: fileManager)
        
        XCTAssertIdentical(sut.storiesViewModel, storiesViewModel, "storiesViewModel")
        XCTAssertEqual(sut.storyId, firstHasPortionStory!.id, "storyId")
        XCTAssertNotEqual(sut.currentPortionIndex, -1, "currentPortionIndex")
    }

    override func tearDownWithError() throws {
        sut = nil
    }
    
    func test_story_ensureStoryIsIdenticalWithStoryId() {
        XCTAssertEqual(sut.story.id, sut.storyId)
    }
    
    func test_portions_ensurePortionsIsValid() {
        XCTAssertFalse(sut.portions.isEmpty)
        XCTAssertEqual(sut.portions.map(\.id), sut.story.portions.map(\.id))
    }

    func text_firstPortionId_ensureTheFirstPortionIdIsValid() {
        let firstPortionId = sut.portions.first?.id
        XCTAssertNotNil(firstPortionId)
        XCTAssertEqual(sut.firstPortionId, firstPortionId)
    }
    
    func test_currentPortionIndex_ensureCurrentPortionIndexIsValid() {
        let index = sut.portions.firstIndex { $0.id == sut.currentPortionId }
        XCTAssertNotNil(index)
        XCTAssertEqual(sut.currentPortionIndex, index)
    }
    
    func test_storyIndex_ensureStoryIndexIsValid() {
        let index = sut.storiesViewModel.stories.firstIndex { $0.id == sut.storyId }
        XCTAssertNotNil(index)
        XCTAssertEqual(sut.storyIndex, index)
    }
    
    func test_currentPortion_ensureCurrentPortionIsValid() {
        XCTAssertEqual(sut.currentPortion?.id, sut.currentPortionId)
    }
    
    func test_barPortionAnimationStatusDict_ensureTheValuesAreValid() {
        let currentPortionId = sut.currentPortionId
        XCTAssertNil(sut.currentPortionAnimationStatus, "currentPortionAnimationStatus")
        XCTAssertNil(sut.barPortionAnimationStatusDict[currentPortionId], "barPortionAnimationStatusDict")
        
        for _ in 1...50 {
            let status = BarPortionAnimationStatus.allCases.randomElement() ?? .inital
            sut.barPortionAnimationStatusDict[currentPortionId] = status
            
            XCTAssertEqual(sut.currentPortionAnimationStatus, status, "currentPortionAnimationStatus")
            XCTAssertEqual(sut.barPortionAnimationStatusDict[currentPortionId], status, "barPortionAnimationStatusDict")
            print(status)
        }
    }
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_ignoreWhenCurrentPortionIsNotFinished() {
        let currentPortionId = sut.currentPortionId
        
        sut.barPortionAnimationStatusDict[currentPortionId] = .none
        
        XCTAssertNotEqual(sut.currentPortionAnimationStatus, .finish, "currentPortionAnimationStatus")
        
        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: {})
        
        XCTAssertEqual(sut.currentPortionId, currentPortionId, "currentPortionId")
    }
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_moveToNextPortion_whenCurrentPortionAnimationFinished() {
        let currentPortionId = sut.currentPortionId
        let currentPortionIdx = sut.portions.firstIndex { $0.id == currentPortionId }
        XCTAssertNotNil(currentPortionIdx, "currentPortionIdx")
        
        let nextPortionId = nextPortionId
        XCTAssertNotNil(nextPortionId, "nextPortionId")
        XCTAssertNotEqual(nextPortionId, currentPortionIdx, "nextPortionId != currentPortionIdx")
        
        sut.barPortionAnimationStatusDict[currentPortionId] = .finish
        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: {})
        
        XCTAssertNotEqual(sut.currentPortionId, currentPortionId, "sut.currentPortionId != currentPortionId")
        XCTAssertEqual(sut.currentPortionId, nextPortionId, "sut.currentPortionId == nextPortionId")
        XCTAssertEqual(sut.barPortionAnimationStatusDict[nextPortionId!], .start, "barPortionAnimationStatus")
    }
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_moveToLastPortion_willGoToNextStory() {
        let currentStoryId = sut.storiesViewModel.currentStoryId
        var callCount = 0
        let withoutNextStoryAction: () -> Void = {
            callCount += 1
        }
        
        while let nextPortionId = nextPortionId {
            let currentPortionId = sut.currentPortionId
            sut.barPortionAnimationStatusDict[sut.currentPortionId] = .finish
            sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: withoutNextStoryAction)
            
            XCTAssertNotEqual(sut.currentPortionId, currentPortionId, "sut.currentPortionId != currentPortionId")
            XCTAssertEqual(sut.currentPortionId, nextPortionId, "sut.currentPortionId == nextPortionId")
            XCTAssertEqual(sut.barPortionAnimationStatusDict[nextPortionId], .start, "barPortionAnimationStatus")
            
            XCTAssertEqual(sut.storiesViewModel.currentStoryId, currentStoryId, "currentStoryId")
            XCTAssertEqual(callCount, 0, "callCount")
        }
        
        sut.barPortionAnimationStatusDict[sut.currentPortionId] = .finish
        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: withoutNextStoryAction)
        
        XCTAssertNotEqual(sut.storiesViewModel.currentStoryId, currentStoryId, "storiesViewModel.currentStoryId != currentStoryId")
        XCTAssertNotNil(nextStoryId, "nextStoryId")
        XCTAssertEqual(sut.storiesViewModel.currentStoryId, nextStoryId, "storiesViewModel.currentStoryId == nextStoryId")
        XCTAssertEqual(callCount, 0, "callCount")
    }
}

// MARK: helpers
extension StoryViewModelTests {
    private var nextPortionId: Int? {
        let currentPortionIdx = sut.portions.firstIndex { $0.id == sut.currentPortionId }
        let nextPortionIdx = currentPortionIdx! + 1
        return nextPortionIdx < sut.portions.count ? sut.portions[nextPortionIdx].id : nil
    }
    
    private var nextStoryId: Int? {
        let currentStoryIdx = sut.storiesViewModel.currentStoryIndex
        let nextStoryIdx = currentStoryIdx! + 1
        return nextStoryIdx < sut.storiesViewModel.stories.count ? sut.portions[nextStoryIdx].id : nil
    }
}
