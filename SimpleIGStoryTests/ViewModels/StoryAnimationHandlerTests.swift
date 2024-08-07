//
//  StoryAnimationHandlerTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 19/03/2024.
//

import XCTest
import Combine
@testable import Simple_IG_Story

final class StoryAnimationHandlerTests: XCTestCase {
    func test_init_setsCurrentPortionAnimationStatusToInitialUponInit() {
        let stories = [makeStory(portions: [makePortion(id: 0)])]
        let (sut, _) = makeSUT(stories: stories)
        
        XCTAssertEqual(sut.currentPortionIndex, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
    }
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_ignoresWhenCurrentPortionAnimationIsNotFinished() {
        let stories = [makeStory(portions: [makePortion(id: 0)])]
        let (sut, _) = makeSUT(stories: stories)
        
        sut.performNextPortionAnimationWhenCurrentPortionFinished()
        
        XCTAssertNotEqual(sut.currentPortionAnimationStatus, .finish)
    }
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_movesToNextPortionWhenCurrentPortionAnimationIsFinished() {
        let stories = [
            makeStory(portions: [
                makePortion(id: 0),
                makePortion(id: 1)
            ])
        ]
        let (sut, _) = makeSUT(stories: stories)
        
        sut.finishPortionAnimation(at: 0)
        
        XCTAssertEqual(sut.currentPortionIndex, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .finish)
        
        sut.performNextPortionAnimationWhenCurrentPortionFinished()
        
        XCTAssertEqual(sut.currentPortionIndex, 1)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start)
    }
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_movesToNextStoryWhenCurrentPortionIsTheLastOne() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)]),
            makeStory(id: 1, portions: [makePortion(id: 1)])
        ]
        let (sut, spy) = makeSUT(stories: stories)
        
        sut.finishPortionAnimation(at: 0)
        sut.performNextPortionAnimationWhenCurrentPortionFinished()
        
        XCTAssertEqual(spy.loggedStoryMoveDirections, [.next])
    }
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_triggersNoNextStoryBlockWhenCurrentPortionIsTheLastOneAndIsTheLastStoryNow() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.isAtLastStory = true
        
        sut.finishPortionAnimation(at: 0)
        
        let exp = expectation(description: "Wait for whenNoNextStory block")
        sut.performNextPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {
            exp.fulfill()
        })
        wait(for: [exp], timeout: 1)
    }
    
    func test_setPortionTransitionDirectionToForward_finishsCurrentBarPortionAnimation() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.isAtFirstStory = true
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
        
        sut.performPortionTransitionAnimation(by: .toForward)
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .finish)
    }
    
    func test_setPortionTransitionDirection_setsToBackwardAtFirstStoryLastPortion_backsToPreviousPortion() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0), makePortion(id: 1)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.isAtFirstStory = true
        
        sut.finishPortionAnimation(at: 0)
        sut.performNextPortionAnimationWhenCurrentPortionFinished()
        
        XCTAssertEqual(sut.currentPortionIndex, 1)
        
        sut.performPortionTransitionAnimation(by: .toBackward)
        
        XCTAssertEqual(sut.currentPortionIndex, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start)
        XCTAssertTrue(spy.noStoryChanges)
    }
    
    func test_setPortionTransitionDirection_setsToBackwardAtFirstStoryFirstPortion_restartsCurrentPortion() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0), makePortion(id: 1)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.isAtFirstStory = true
        
        sut.performPortionTransitionAnimation(by: .toBackward)
        
        XCTAssertEqual(sut.currentPortionIndex, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start)
        
        sut.performPortionTransitionAnimation(by: .toBackward)
        
        XCTAssertEqual(sut.currentPortionIndex, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .restart)
        XCTAssertTrue(spy.noStoryChanges)
    }
    
    func test_setPortionTransitionDirection_setsToBackwardAtSecondStoryFirstPortion_backsToPreviousStory() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)]),
            makeStory(id: 1, portions: [makePortion(id: 1)])
        ]
        let (sut, spy) = makeSUT(storyId: 1, stories: stories)
        spy.currentStoryId = 1
        
        XCTAssertEqual(sut.currentPortionIndex, 0)
        XCTAssertTrue(spy.noStoryChanges)
        
        sut.performPortionTransitionAnimation(by: .toBackward)
        
        XCTAssertEqual(sut.currentPortionIndex, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
        XCTAssertEqual(spy.loggedStoryMoveDirections, [.previous])
    }
    
    func test_updateBarPortionAnimationStatusWhenDragging_pausesPortionAnimationWhenIsDragging() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, spy) = makeSUT(stories: stories)
        
        sut.startProgressBarAnimation()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start)
        
        spy.setIsDragging(true)
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause)
    }
    
    func test_updateBarPortionAnimationStatusWhenDragging_resumesPortionAnimationAfterDraggedAndStayedInSameStory() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, spy) = makeSUT(stories: stories)
        
        sut.startProgressBarAnimation()
        spy.setIsDragging(true)
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause)
        
        spy.isSameStoryAfterDragging = true
        spy.setIsDragging(false)
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .resume)
    }
    
    func test_startProgressBarAnimation_ignoresWhenIsNotCurrentStory() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)]),
            makeStory(id: 1, portions: [makePortion(id: 1)])
        ]
        let (sut, spy) = makeSUT(storyId: 1, stories: stories)
        spy.currentStoryId = 0
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
        
        sut.startProgressBarAnimation()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
    }
    
    func test_startProgressBarAnimation_ignoresWhenPortionIsAnimating() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, spy) = makeSUT(stories: stories)
        
        setupForCurrentPortionAnimationResumesStatus(on: sut, with: spy)
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .resume)
        
        sut.startProgressBarAnimation()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .resume)
    }
    
    func test_startProgressBarAnimation_startsAnimation() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, _) = makeSUT(stories: stories)
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
        
        sut.startProgressBarAnimation()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start)
    }
    
    func test_pausePortionAnimation_ignoresWhenNotAnimating() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, _) = makeSUT(stories: stories)
        
        XCTAssertNotEqual(sut.currentPortionAnimationStatus, .pause)
        
        sut.pausePortionAnimation()
        
        XCTAssertNotEqual(sut.currentPortionAnimationStatus, .pause)
    }
    
    func test_pausePortionAnimation_pausesWhenAnimating() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.isAtFirstStory = true
        
        sut.startProgressBarAnimation()
        sut.pausePortionAnimation()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause)
        
        sut.resumePortionAnimation()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .resume)
        
        sut.pausePortionAnimation()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause)
        
        sut.startProgressBarAnimation()
        sut.performPortionTransitionAnimation(by: .toBackward)
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .restart)
        
        sut.pausePortionAnimation()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause)
    }
    
    func test_resumePortionAnimation_ignoresWhenAnimationNotPaused() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, _) = makeSUT(stories: stories)
        
        XCTAssertNotEqual(sut.currentPortionAnimationStatus, .resume)
        
        sut.resumePortionAnimation()
        
        XCTAssertNotEqual(sut.currentPortionAnimationStatus, .resume)
    }
    
    func test_resumePortionAnimation_resumesWhenAnimationPaused() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, _) = makeSUT(stories: stories)
        
        sut.startProgressBarAnimation()
        sut.pausePortionAnimation()
        sut.resumePortionAnimation()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .resume)
    }
    
    func test_moveToCurrentPortion_ignoresWhenPortionIndexInvalid() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0), makePortion(id: 1)])]
        let (sut, _) = makeSUT(stories: stories)
        
        XCTAssertEqual(sut.currentPortionIndex, 0)
        
        let invalidPortionIndex = 2
        sut.moveCurrentPortion(at: invalidPortionIndex)
        
        XCTAssertEqual(sut.currentPortionIndex, 0)
    }
    
    func test_moveToCurrentPortion_movesToCorrectPortionWhenPortionIndexValid() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0), makePortion(id: 1)])]
        let (sut, _) = makeSUT(stories: stories)
        
        XCTAssertEqual(sut.currentPortionIndex, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
        
        let validPortionIndex = 1
        sut.moveCurrentPortion(at: validPortionIndex)
        
        XCTAssertEqual(sut.currentPortionIndex, 1)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(storyId: Int = 0,
                         stories: [StoryDTO] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: StoryAnimationHandler, spy: ParentStoryViewModelSpy) {
        let spy = ParentStoryViewModelSpy()
        spy.stories = stories
        let sut = StoryAnimationHandler(storyId: storyId, currentStoryAnimationHandler: spy)
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, spy)
    }
    
    private func setupForCurrentPortionAnimationResumesStatus(on sut: StoryAnimationHandler,
                                                              with spy: ParentStoryViewModelSpy) {
        sut.startProgressBarAnimation()
        spy.setIsDragging(true)
        
        spy.isSameStoryAfterDragging = true
        spy.setIsDragging(false)
    }
    
    private class ParentStoryViewModelSpy: ObservableObject, CurrentStoryAnimationHandler {
        enum StoryMoveDirection {
            case previous, next
        }
        
        var isAtFirstStory = false
        var isAtLastStory = false
        var currentStoryId = 0
        var stories = [StoryDTO]()
        var isSameStoryAfterDragging = false
        
        private let isDraggingPublisher = CurrentValueSubject<Bool, Never>(false)
        private(set) var loggedStoryMoveDirections = [StoryMoveDirection]()
        var noStoryChanges: Bool {
            loggedStoryMoveDirections.isEmpty
        }
        
        func getIsDraggingPublisher() -> AnyPublisher<Bool, Never> {
            isDraggingPublisher.eraseToAnyPublisher()
        }
        
        func getPortionCount(by storyId: Int) -> Int {
            stories.first(where: { $0.id == storyId })?.portions.count ?? 0
        }
        
        func setIsDragging(_ isDragging: Bool) {
            isDraggingPublisher.send(isDragging)
        }
        
        func moveToPreviousStory() {
            loggedStoryMoveDirections.append(.previous)
        }
        
        func moveToNextStory() {
            loggedStoryMoveDirections.append(.next)
        }
    }
}

private extension StoryAnimationHandler {
    func performNextPortionAnimationWhenCurrentPortionFinished() {
        performNextPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {})
    }
}

private extension CGFloat {
    static var toBackward: CGFloat {
        .screenWidth/2
    }
    
    static var toForward: CGFloat {
        .screenWidth/2 + 1
    }
}
