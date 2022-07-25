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
    var storiesViewModel: StoriesViewModel!
    
    override func setUpWithError() throws {
        storiesViewModel = StoriesViewModel(fileManager: LocalFileManager())
        
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
        XCTAssertNotEqual(sut.currentPortionId, -1, "currentPortionId")
    }

    override func tearDownWithError() throws {
        sut = nil
        storiesViewModel = nil
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
        XCTAssertEqual(sut.currentPortionAnimationStatus, .inital, "currentPortionAnimationStatus")
        XCTAssertEqual(sut.barPortionAnimationStatusDict[currentPortionId], .inital, "barPortionAnimationStatusDict")
        
        for _ in 1...30 {
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
            let savedCurrentPortionId = sut.currentPortionId
            sut.barPortionAnimationStatusDict[sut.currentPortionId] = .finish
            sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: withoutNextStoryAction)
            
            XCTAssertNotEqual(sut.currentPortionId, savedCurrentPortionId, "sut.currentPortionId != savedCurrentPortionId")
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
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_theCompleteFlowFromBeginningToTheLastPortionOfTheLastStory() {
        let storyCount = hasPortionStories.count
        var savedCurrentStoryId = sut.storiesViewModel.currentStoryId
        var callCount = 0
        let withoutNextStoryAction: () -> Void = {
            callCount += 1
        }
        
        for i in 0..<storyCount {
            while let nextPortionId = nextPortionId {
                let savedCurrentPortionId = sut.currentPortionId
                sut.barPortionAnimationStatusDict[sut.currentPortionId] = .finish
                sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: withoutNextStoryAction)
                
                XCTAssertNotEqual(sut.currentPortionId, savedCurrentPortionId, "sut.currentPortionId != savedCurrentPortionId")
                XCTAssertEqual(sut.currentPortionId, nextPortionId, "sut.currentPortionId == nextPortionId")
                XCTAssertEqual(sut.barPortionAnimationStatusDict[nextPortionId], .start, "barPortionAnimationStatus")
                
                XCTAssertEqual(sut.storiesViewModel.currentStoryId, savedCurrentStoryId, "currentStoryId")
                XCTAssertEqual(callCount, 0, "callCount")
            }
            
            if i < storyCount - 1 {
                sut.barPortionAnimationStatusDict[sut.currentPortionId] = .finish
                sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: withoutNextStoryAction)
                
                XCTAssertNotEqual(sut.storiesViewModel.currentStoryId, savedCurrentStoryId, "storiesViewModel.currentStoryId != savedCurrentStoryId")
                XCTAssertNotNil(nextStoryId, "nextStoryId")
                XCTAssertEqual(sut.storiesViewModel.currentStoryId, nextStoryId, "storiesViewModel.currentStoryId == nextStoryId")
                XCTAssertEqual(callCount, 0, "callCount")
                
                savedCurrentStoryId = sut.storiesViewModel.currentStoryId
            } else {
                sut.barPortionAnimationStatusDict[sut.currentPortionId] = .finish
                sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: withoutNextStoryAction)
                
                XCTAssertEqual(callCount, 1, "callCount")
            }
        }
    }
    
    func test_currentStoryId_ensureItIsEqualToStoriesViewModelCurrentStoryId() {
        XCTAssertEqual(sut.currentStoryId, sut.storiesViewModel.currentStoryId)
    }
    
    func test_performProgressBarAnimation_setPortionTransitionDirectionToForward_currentBarPortionAnimationStatusWillBeFinish() {
        XCTAssertEqual(sut.currentPortionAnimationStatus, .inital)
        setPortionTransitionDirectionForward()
        XCTAssertEqual(sut.currentPortionAnimationStatus, .finish)
    }
    
    func test_performProgressBarAnimation_setPortionTransitionDirectionToBackward_firstStoryFirstPortion_startCurrentPortionAnimation() {
        XCTAssertEqual(sut.currentPortionAnimationStatus, .inital, "currentPortionAnimationStatus")
        XCTAssertEqual(sut.currentPortionId, sut.firstPortionId, "currentPortionId == firstPortionId")
        
        setPortionTransitionDirectionBackward()
        
        XCTAssertEqual(sut.currentPortionId, sut.firstPortionId, "currentPortionId == firstPortionId")
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start, "currentPortionAnimationStatus")
        
        setPortionTransitionDirectionBackward()
        
        XCTAssertEqual(sut.currentPortionId, sut.firstPortionId, "currentPortionId == firstPortionId")
        XCTAssertEqual(sut.currentPortionAnimationStatus, .restart, "currentPortionAnimationStatus")
    }
    
    func test_performProgressBarAnimation_setTransitionDirectionToBackward_firstPortionNotFirstStory_backToPreviousStory() {
        sut = make2ndStorySUT()
        
        let previousCurrentStoryId = sut.currentStoryId
        sut.storiesViewModel.moveCurrentStory(to: .next)
        sut.setCurrentBarPortionAnimationStatus(to: .start)
        
        XCTAssertNotEqual(sut.currentStoryId, previousCurrentStoryId, "currentStoryId != previousCurrentStoryId")
        let firstPortionId = sut.firstPortionId!
        XCTAssertEqual(sut.currentPortionId, firstPortionId, "currentPortionId == firstPortionId")
        
        setPortionTransitionDirectionBackward()
        
        XCTAssertEqual(sut.barPortionAnimationStatusDict[firstPortionId], .inital)
        XCTAssertEqual(sut.currentStoryId, previousCurrentStoryId, "currentStoryId == previousCurrentStoryId")
    }
    
    func test_performProgressBarAnimation_setTransitionDirectionToBackward_notFirstPortion_backToPreviousPortion() {
        let previousPortionId = sut.currentPortionId
        sut.setCurrentBarPortionAnimationStatus(to: .finish)
        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: {})
        XCTAssertEqual(sut.barPortionAnimationStatusDict[previousPortionId], .finish)
        XCTAssertNotEqual(sut.currentPortionId, previousPortionId, "currentPortionId != previousPortionId")
        
        let portionId = sut.currentPortionId
        setPortionTransitionDirectionBackward()
        
        XCTAssertEqual(sut.barPortionAnimationStatusDict[portionId], .inital)
        XCTAssertEqual(sut.currentPortionId, previousPortionId, "currentPortionId == previousPortionId")
        XCTAssertEqual(sut.barPortionAnimationStatusDict[previousPortionId], .start, "currentBarPortionAnimationStatus")
    }
    
    func test_updateBarPortionAnimationStatusWhenDrag_isDragging_andAnimationStatusIsStart_pauseAnimation() {
        sut.setCurrentBarPortionAnimationStatus(to: .start)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start, "currentPortionAnimationStatus")
        XCTAssertTrue(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
        
        storiesViewModel.isDragging = true
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause, "currentPortionAnimationStatus")
        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
    }
    
    func test_updateBarPortionAnimationStatusWhenDrag_isDragging_andAnimationStatusIsInital_ignore() {
        XCTAssertEqual(sut.currentPortionAnimationStatus, .inital, "currentPortionAnimationStatus")
        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
        
        storiesViewModel.isDragging = true
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .inital, "currentPortionAnimationStatus")
        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
    }
    
    func test_updateBarPortionAnimationStatusWhenDrag_dragged_notSameStoryAndCurrentPortionNotAnimated_startAnimation() {
        let secondSUT = make2ndStorySUT()
        sut.setCurrentBarPortionAnimationStatus(to: .start)
        XCTAssertNotIdentical(sut, secondSUT)
        
        XCTAssertTrue(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
        XCTAssertEqual(storiesViewModel.currentStoryId, sut.storyId, "sut is current")
        
        storiesViewModel.isDragging = true
        
        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause, "currentPortionAnimationStatus")
        
        // simulate dragged from the 1st story to the 2nd story.
        storiesViewModel.moveCurrentStory(to: .next)
        storiesViewModel.isDragging = false
        
        XCTAssertEqual(storiesViewModel.currentStoryId, secondSUT.storyId, "secondSUT is now current")
        XCTAssertFalse(sut.isCurrentPortionAnimating, "1st story isCurrentPortionAnimating")
        XCTAssertEqual(secondSUT.currentPortionAnimationStatus, .start, "2nd story currentPortionAnimationStatus")
    }
    
    func test_updateBarPortionAnimationStatusWhenDrag_dragged_sameStory_resumeAnimation() {
        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
        
        sut.setCurrentBarPortionAnimationStatus(to: .start)
        
        XCTAssertTrue(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start, "currentPortionAnimationStatus")
        
        storiesViewModel.isDragging = true
        
        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause, "currentPortionAnimationStatus")
        
        storiesViewModel.isDragging = false
        
        XCTAssertTrue(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
        XCTAssertEqual(sut.currentPortionAnimationStatus, .resume, "currentPortionAnimationStatus")
    }
    
    func test_startProgressBarAnimation_currentStory_andCurrentPortionIsAnimating_ignore() {
        sut.setCurrentBarPortionAnimationStatus(to: .resume)
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .resume, "currentPortionAnimationStatus")
        
        sut.startProgressBarAnimation()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .resume, "currentPortionAnimationStatus")
    }
    
    func test_startProgressBarAnimation_currentStory_andCurrentPortionIsNotAnimating_startAnmation() {
        XCTAssertEqual(sut.currentPortionAnimationStatus, .inital, "currentPortionAnimationStatus")
        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
        
        sut.startProgressBarAnimation()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start, "currentPortionAnimationStatus")
        XCTAssertTrue(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
    }
    
    func test_startProgressBarAnimation_currentStory_andCurrentPortionIsNotAnimating_butNotCurrentStory_ignore() {
        sut.setCurrentBarPortionAnimationStatus(to: .pause)
        storiesViewModel.moveCurrentStory(to: .next)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause, "currentPortionAnimationStatus")
        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
        
        sut.startProgressBarAnimation()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause, "currentPortionAnimationStatus")
        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
    }
}

// MARK: helpers
extension StoryViewModelTests {
    private var hasPortionStories: [Story] {
        sut.storiesViewModel.stories.filter{ $0.hasPortion }
    }
    
    private var nextPortionId: Int? {
        let currentPortionIdx = sut.portions.firstIndex { $0.id == sut.currentPortionId }
        let nextPortionIdx = currentPortionIdx! + 1
        return nextPortionIdx < sut.portions.count ? sut.portions[nextPortionIdx].id : nil
    }
    
    private var nextStoryId: Int? {
        let storyCount = sut.storiesViewModel.stories.count
        let currentStoryIdx = sut.storiesViewModel.currentStoryIndex
        let nextStoryIdx = currentStoryIdx! + 1
        return nextStoryIdx < storyCount ? sut.storiesViewModel.stories[nextStoryIdx].id : nil
    }
    
    private func setPortionTransitionDirectionForward() {
        sut.setPortionTransitionDirection(by: (.screenWidth / 2) + 40)
    }
    
    private func setPortionTransitionDirectionBackward() {
        sut.setPortionTransitionDirection(by: (.screenWidth / 2) - 40)
    }
    
    private func make2ndStorySUT() -> StoryViewModel {
        let secondStory = hasPortionStories[1]
        return StoryViewModel(storyId: secondStory.id, storiesViewModel: storiesViewModel, fileManager: LocalFileManager())
    }
}
