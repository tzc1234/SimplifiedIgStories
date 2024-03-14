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
    
//    func test_currentStoryId_ensureItIsEqualToStoriesViewModelCurrentStoryId() {
//        XCTAssertEqual(sut.currentStoryId, storiesViewModel.currentStoryId)
//    }
//    
//    func test_performProgressBarAnimation_setPortionTransitionDirectionToForward_currentBarPortionAnimationStatusWillBeFinish() {
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
//        setPortionTransitionDirectionForward()
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .finish)
//    }
//    
//    func test_performProgressBarAnimation_setPortionTransitionDirectionToBackward_firstStoryFirstPortion_startCurrentPortionAnimation() {
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial, "currentPortionAnimationStatus")
//        XCTAssertEqual(sut.currentPortionId, sut.firstPortionId, "currentPortionId == firstPortionId")
//        
//        setPortionTransitionDirectionBackward()
//        
//        XCTAssertEqual(sut.currentPortionId, sut.firstPortionId, "currentPortionId == firstPortionId")
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .start, "currentPortionAnimationStatus")
//        
//        setPortionTransitionDirectionBackward()
//        
//        XCTAssertEqual(sut.currentPortionId, sut.firstPortionId, "currentPortionId == firstPortionId")
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .restart, "currentPortionAnimationStatus")
//    }
//    
//    func test_performProgressBarAnimation_setTransitionDirectionToBackward_firstPortionNotFirstStory_backToPreviousStory() {
//        sut = make2ndStorySUT()
//        
//        let previousCurrentStoryId = sut.currentStoryId
//        storiesViewModel.moveCurrentStory(to: .next)
////        sut.setCurrentBarPortionAnimationStatus(to: .start)
//        
//        XCTAssertNotEqual(sut.currentStoryId, previousCurrentStoryId, "currentStoryId != previousCurrentStoryId")
//        let firstPortionId = sut.firstPortionId!
//        XCTAssertEqual(sut.currentPortionId, firstPortionId, "currentPortionId == firstPortionId")
//        
//        setPortionTransitionDirectionBackward()
//        
//        XCTAssertEqual(sut.barPortionAnimationStatusDict[firstPortionId], .initial)
//        XCTAssertEqual(sut.currentStoryId, previousCurrentStoryId, "currentStoryId == previousCurrentStoryId")
//    }
//    
//    func test_performProgressBarAnimation_setTransitionDirectionToBackward_notFirstPortion_backToPreviousPortion() {
//        let previousPortionId = sut.currentPortionId
////        sut.setCurrentBarPortionAnimationStatus(to: .finish)
//        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: {})
//        XCTAssertEqual(sut.barPortionAnimationStatusDict[previousPortionId], .finish)
//        XCTAssertNotEqual(sut.currentPortionId, previousPortionId, "currentPortionId != previousPortionId")
//        
//        let portionId = sut.currentPortionId
//        setPortionTransitionDirectionBackward()
//        
//        XCTAssertEqual(sut.barPortionAnimationStatusDict[portionId], .initial)
//        XCTAssertEqual(sut.currentPortionId, previousPortionId, "currentPortionId == previousPortionId")
//        XCTAssertEqual(sut.barPortionAnimationStatusDict[previousPortionId], .start, "currentBarPortionAnimationStatus")
//    }
//    
//    func test_updateBarPortionAnimationStatusWhenDrag_isDragging_andAnimationStatusIsStart_pauseAnimation() {
////        sut.setCurrentBarPortionAnimationStatus(to: .start)
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .start, "currentPortionAnimationStatus")
//        XCTAssertTrue(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//        
//        storiesViewModel.isDragging = true
//        
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause, "currentPortionAnimationStatus")
//        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//    }
//    
//    func test_updateBarPortionAnimationStatusWhenDrag_isDragging_andAnimationStatusIsInital_ignore() {
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial, "currentPortionAnimationStatus")
//        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//        
//        storiesViewModel.isDragging = true
//        
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial, "currentPortionAnimationStatus")
//        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//    }
//    
//    func test_updateBarPortionAnimationStatusWhenDrag_dragged_notSameStoryAndCurrentPortionNotAnimated_startAnimation() {
//        let secondSUT = make2ndStorySUT()
////        sut.setCurrentBarPortionAnimationStatus(to: .start)
//        XCTAssertNotIdentical(sut, secondSUT)
//        
//        XCTAssertTrue(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//        XCTAssertEqual(storiesViewModel.currentStoryId, sut.storyId, "sut is current")
//        
//        storiesViewModel.isDragging = true
//        
//        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause, "currentPortionAnimationStatus")
//        
//        // simulate dragged from the 1st story to the 2nd story.
//        storiesViewModel.moveCurrentStory(to: .next)
//        storiesViewModel.isDragging = false
//        
//        XCTAssertEqual(storiesViewModel.currentStoryId, secondSUT.storyId, "secondSUT is now current")
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial, "1st story currentPortionAnimationStatus")
//        XCTAssertEqual(secondSUT.currentPortionAnimationStatus, .start, "2nd story currentPortionAnimationStatus")
//    }
//    
//    func test_updateBarPortionAnimationStatusWhenDrag_dragged_sameStory_resumeAnimation() {
//        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//        
////        sut.setCurrentBarPortionAnimationStatus(to: .start)
//        
//        XCTAssertTrue(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .start, "currentPortionAnimationStatus")
//        
//        storiesViewModel.isDragging = true
//        
//        XCTAssertFalse(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .pause, "currentPortionAnimationStatus")
//        
//        storiesViewModel.isDragging = false
//        
//        XCTAssertTrue(sut.isCurrentPortionAnimating, "isCurrentPortionAnimating")
//        XCTAssertEqual(sut.currentPortionAnimationStatus, .resume, "currentPortionAnimationStatus")
//    }
//    
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
    
    private func makeSUT(stories: [Story] = []) -> (sut: StoryViewModel, spy: ParentStoryViewModelSpy) {
        let spy = ParentStoryViewModelSpy()
        spy.stories = stories
        let sut = StoryViewModel(
            storyId: 0,
            parentViewModel: spy,
            fileManager: DummyFileManager(),
            mediaSaver: DummyMediaSaver()
        )
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
        
        private(set) var loggedStoryMoveDirections = [StoryMoveDirection]()
        
        func getIsDraggingPublisher() -> AnyPublisher<Bool, Never> {
            CurrentValueSubject(false).eraseToAnyPublisher()
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
