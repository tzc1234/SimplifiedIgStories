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
    func test_init_setsCurrentPortionAnimationStatusToInitial() {
        let stories = [makeStory(portions: [makePortion(id: 0)])]
        let (sut, _) = makeSUT(stories: stories)
        
        XCTAssertEqual(sut.currentPortionId, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
    }
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_ignoresWhenCurrentPortionAnimationIsNotFinished() {
        let stories = [makeStory(portions: [makePortion(id: 0)])]
        let (sut, _) = makeSUT(stories: stories)
        
        sut.performNextPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {})
        
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
        
        sut.finishPortionAnimation(for: 0)
        sut.performNextPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {})
        
        XCTAssertEqual(sut.currentPortionId, 1)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start)
    }
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_movesToNextStoryWhenCurrentPortionIsTheLastOne() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)]),
            makeStory(id: 1, portions: [makePortion(id: 1)])
        ]
        let (sut, spy) = makeSUT(stories: stories)
        
        sut.finishPortionAnimation(for: 0)
        sut.performNextPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {})
        
        XCTAssertEqual(spy.loggedStoryMoveDirections, [.next])
    }
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_triggersNoNextStoryBlockWhenCurrentPortionIsTheLastOneAndIsTheLastStoryNow() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.isAtLastStory = true
        
        sut.finishPortionAnimation(for: 0)
        
        let exp = expectation(description: "Wait for whenNoNextStory block")
        sut.performNextPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {
            exp.fulfill()
        })
        wait(for: [exp], timeout: 1)
    }
    
    func test_setPortionTransitionDirection_setsToForward_finishsCurrentBarPortionAnimation() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.isAtFirstStory = true
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
        
        sut.performPortionTransitionAnimation(by: .forwardValue)
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .finish)
    }
    
    func test_setPortionTransitionDirection_setsToBackwardAtFirstStoryLastPortion_backToPreviousPortion() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0), makePortion(id: 1)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.isAtFirstStory = true
        
        sut.finishPortionAnimation(for: 0)
        sut.performNextPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {})
        
        XCTAssertEqual(sut.currentPortionId, 1)
        
        sut.performPortionTransitionAnimation(by: .backwardValue)
        
        XCTAssertEqual(sut.currentPortionId, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start)
    }
    
    func test_setPortionTransitionDirection_setsToBackwardAtFirstStoryFirstPortion_restartCurrentPortion() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0), makePortion(id: 1)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.isAtFirstStory = true
        
        sut.performPortionTransitionAnimation(by: .backwardValue)
        
        XCTAssertEqual(sut.currentPortionId, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start)
        
        sut.performPortionTransitionAnimation(by: .backwardValue)
        
        XCTAssertEqual(sut.currentPortionId, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .restart)
    }
    
    func test_setPortionTransitionDirection_setsToBackwardAtSecondStoryFirstPortion_backToPreviousStory() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)]),
            makeStory(id: 1, portions: [makePortion(id: 1)])
        ]
        let (sut, spy) = makeSUT(storyId: 1, stories: stories)
        
        XCTAssertEqual(sut.currentPortionId, 1)
        XCTAssertEqual(spy.loggedStoryMoveDirections, [])
        
        sut.performPortionTransitionAnimation(by: .backwardValue)
        
        XCTAssertEqual(sut.currentPortionId, 1)
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
        sut.performPortionTransitionAnimation(by: .backwardValue)
        
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
        
        XCTAssertEqual(sut.currentPortionId, 0)
        
        let invalidPortionIndex = 2
        sut.moveToCurrentPortion(for: invalidPortionIndex)
        
        XCTAssertEqual(sut.currentPortionId, 0)
    }
    
    func test_moveToCurrentPortion_movesToCorrectPortionWhenPortionIndexValid() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0), makePortion(id: 1)])]
        let (sut, _) = makeSUT(stories: stories)
        
        XCTAssertEqual(sut.currentPortionId, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
        
        let validPortionIndex = 1
        sut.moveToCurrentPortion(for: validPortionIndex)
        
        XCTAssertEqual(sut.currentPortionId, 1)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(storyId: Int = 0,
                         stories: [Story] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: StoryAnimationHandler, spy: ParentStoryViewModelSpy) {
        let spy = ParentStoryViewModelSpy()
        spy.stories = stories
        let sut = StoryAnimationHandler(
            storyId: storyId,
            currentStoryAnimationHandler: spy
        )
        
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
        var stories = [Story]()
        var isSameStoryAfterDragging = false
        
        private let isDraggingPublisher = CurrentValueSubject<Bool, Never>(false)
        private(set) var loggedStoryMoveDirections = [StoryMoveDirection]()
        
        func getIsDraggingPublisher() -> AnyPublisher<Bool, Never> {
            isDraggingPublisher.eraseToAnyPublisher()
        }
        
        func getPortions(by storyId: Int) -> [Portion] {
            stories.first(where: { $0.id == storyId })?.portions ?? []
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
    
    private class DummyFileManager: FileManageable {
        func saveImage(_ image: UIImage, fileName: String) throws -> URL {
            URL(string: "file://any-image.jpg")!
        }
        
        func getImage(for url: URL) -> UIImage? {
            nil
        }
        
        func delete(for url: URL) throws {}
    }

    private class DummyMediaSaver: MediaSaver {
        func saveImageData(_ data: Data) async throws {}
        func saveVideo(by url: URL) async throws {}
    }
}

private extension CGFloat {
    static var backwardValue: CGFloat {
        .screenWidth/2
    }
    
    static var forwardValue: CGFloat {
        .screenWidth/2 + 1
    }
}