//
//  StoryViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 24/07/2022.
//

import XCTest
import Combine
@testable import Simple_IG_Story

final class StoryViewModelTests: XCTestCase {
    func test_init_setsCurrentPortionAnimationStatusToInitial() {
        let stories = [makeStory(portions: [makePortion(id: 0)])]
        let (sut, _) = makeSUT(stories: stories)
        
        XCTAssertEqual(sut.currentPortionId, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
    }
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_ignoresWhenCurrentPortionAnimationIsNotFinished() {
        let stories = [makeStory(portions: [makePortion(id: 0)])]
        let (sut, _) = makeSUT(stories: stories)
        
        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {})
        
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
        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {})
        
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
        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {})
        
        XCTAssertEqual(spy.loggedStoryMoveDirections, [.next])
    }
    
    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_triggersNoNextStoryBlockWhenCurrentPortionIsTheLastOneAndIsTheLastStoryNow() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.isNowAtLastStory = true
        
        sut.finishPortionAnimation(for: 0)
        
        let exp = expectation(description: "Wait for whenNoNextStory block")
        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {
            exp.fulfill()
        })
        wait(for: [exp], timeout: 1)
    }
    
    func test_setPortionTransitionDirection_setsToForward_finishsCurrentBarPortionAnimation() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.firstCurrentStoryId = 0
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
        
        sut.setPortionTransitionDirection(by: .forwardValue)
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .finish)
    }
    
    func test_setPortionTransitionDirection_setsToBackwardAtFirstStoryLastPortion_backToPreviousPortion() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0), makePortion(id: 1)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.firstCurrentStoryId = 0
        
        sut.finishPortionAnimation(for: 0)
        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {})
        
        XCTAssertEqual(sut.currentPortionId, 1)
        
        sut.setPortionTransitionDirection(by: .backwardValue)
        
        XCTAssertEqual(sut.currentPortionId, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start)
    }
    
    func test_setPortionTransitionDirection_setsToBackwardAtFirstStoryFirstPortion_restartCurrentPortion() {
        let stories = [makeStory(id: 0, portions: [makePortion(id: 0), makePortion(id: 1)])]
        let (sut, spy) = makeSUT(stories: stories)
        spy.firstCurrentStoryId = 0
        
        sut.setPortionTransitionDirection(by: .backwardValue)
        
        XCTAssertEqual(sut.currentPortionId, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .start)
        
        sut.setPortionTransitionDirection(by: .backwardValue)
        
        XCTAssertEqual(sut.currentPortionId, 0)
        XCTAssertEqual(sut.currentPortionAnimationStatus, .restart)
    }
    
    func test_setPortionTransitionDirection_setsToBackwardAtSecondStoryFirstPortion_backToPreviousStory() {
        let stories = [
            makeStory(id: 0, portions: [makePortion(id: 0)]),
            makeStory(id: 1, portions: [makePortion(id: 1)])
        ]
        let (sut, spy) = makeSUT(storyId: 1, stories: stories)
        spy.firstCurrentStoryId = 0
        
        XCTAssertEqual(sut.currentPortionId, 1)
        XCTAssertEqual(spy.loggedStoryMoveDirections, [])
        
        sut.setPortionTransitionDirection(by: .backwardValue)
        
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
    
//    func test_startProgressBarAnimation_currentStory_andCurrentPortionIsAnimating_ignore() {
////        sut.setCurrentBarPortionAnimationStatus(to: .resume)
//        
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .resume, "currentPortionAnimationStatus")
//        
//        sut.startProgressBarAnimation()
//        
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .resume, "currentPortionAnimationStatus")
//    }
//    
//    func test_startProgressBarAnimation_currentStory_andCurrentPortionIsNotAnimating_startAnmation() {
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial, "currentPortionAnimationStatus")
//        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//        
//        sut.startProgressBarAnimation()
//        
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .start, "currentPortionAnimationStatus")
//        XCTAssertTrue(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//    }
//    
//    func test_startProgressBarAnimation_currentStory_andCurrentPortionIsNotAnimating_butNotCurrentStory_ignore() {
////        sut.setCurrentBarPortionAnimationStatus(to: .pause)
//        storiesViewModel.moveCurrentStory(to: .next)
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause, "currentPortionAnimationStatus")
//        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//        
//        sut.startProgressBarAnimation()
//        
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause, "currentPortionAnimationStatus")
//        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//    }
    
    // MARK: - Helpers
    
    private func makeSUT(storyId: Int = 0,
                         stories: [Story] = [], 
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: StoryViewModel, spy: ParentStoryViewModelSpy) {
        let spy = ParentStoryViewModelSpy()
        spy.stories = stories
        let sut = StoryViewModel(
            storyId: storyId,
            parentViewModel: spy,
            fileManager: DummyFileManager(),
            mediaSaver: DummyMediaSaver()
        )
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, spy)
    }
    
    private func makePortion(id: Int = 0) -> Portion {
        Portion(id: id, duration: 1, resourceURL: nil, type: .image)
    }
    
    private func makeStory(id: Int = 0, portions: [Portion] = []) -> Story {
        Story(
            id: id,
            lastUpdate: nil,
            portions: portions,
            user: User(
                id: 0,
                name: "user",
                avatarURL: nil,
                isCurrentUser: true
            )
        )
    }
    
    private class ParentStoryViewModelSpy: ObservableObject, ParentStoryViewModel {
        var stories = [Story]()
        var firstCurrentStoryId: Int? = nil
        var currentStoryId = 0
        private(set) var shouldCubicRotation = true
        var isNowAtLastStory = false
        var isSameStoryAfterDragging = false
        
        private let isDraggingPublisher = CurrentValueSubject<Bool, Never>(false)
        private(set) var loggedStoryMoveDirections = [StoryMoveDirection]()
        
        func getIsDraggingPublisher() -> AnyPublisher<Bool, Never> {
            isDraggingPublisher.eraseToAnyPublisher()
        }
        
        func setIsDragging(_ isDragging: Bool) {
            isDraggingPublisher.send(isDragging)
        }
        
        func moveCurrentStory(to direction: StoryMoveDirection) {
            loggedStoryMoveDirections.append(direction)
        }
    }
    
    private class DummyFileManager: ImageFileManageable {
        func saveImage(_ image: UIImage, fileName: String) throws -> URL {
            URL(string: "file://any-image.jpg")!
        }
        
        func getImage(for url: URL) -> UIImage? {
            nil
        }
        
        func deleteImage(for url: URL) throws {}
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

//extension StoryViewModelTests {
//    private var hasPortionStories: [Story] {
//        storiesViewModel.stories.filter { $0.hasPortion }
//    }
    
//    private var nextPortionId: Int? {
//        let currentPortionIdx = sut.portions.firstIndex { $0.id == sut.currentPortionId }
//        let nextPortionIdx = currentPortionIdx! + 1
//        return nextPortionIdx < sut.portions.count ? sut.portions[nextPortionIdx].id : nil
//    }
    
//    private var nextStoryId: Int? {
//        let storyCount = storiesViewModel.stories.count
//        let currentStoryIdx = storiesViewModel.currentStoryIndex
//        let nextStoryIdx = currentStoryIdx! + 1
//        return nextStoryIdx < storyCount ? storiesViewModel.stories[nextStoryIdx].id : nil
//    }
//    
//    private func setPortionTransitionDirectionForward() {
//        sut.setPortionTransitionDirection(by: (.screenWidth / 2) + 40)
//    }
//    
//    private func setPortionTransitionDirectionBackward() {
//        sut.setPortionTransitionDirection(by: (.screenWidth / 2) - 40)
//    }
//    
//    private func make2ndStorySUT() -> StoryViewModel {
//        let secondStory = hasPortionStories[1]
//        return StoryViewModel(
//            storyId: secondStory.id,
//            parentViewModel: storiesViewModel,
//            fileManager: LocalImageFileManager(),
//            mediaSaver: LocalMediaSaver()
//        )
//    }
//}
