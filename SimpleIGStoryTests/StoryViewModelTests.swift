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
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.currentPortionAnimationStatus, .initial)
    }
    
//    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_ignoreWhenCurrentPortionIsNotFinished() {
//        let currentPortionId = sut.currentPortionId
//        
////        sut.barPortionAnimationStatusDict[currentPortionId] = .none
//        
//        XCTAssertNotEqual(sut.currentPortionAnimationStatus, .finish, "currentPortionAnimationStatus")
//        
//        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(whenNoNextStory: {})
//        
//        XCTAssertEqual(sut.currentPortionId, currentPortionId, "currentPortionId")
//    }
    
//    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_moveToNextPortion_whenCurrentPortionAnimationFinished() {
//        let currentPortionId = sut.currentPortionId
//        let currentPortionIdx = sut.portions.firstIndex { $0.id == currentPortionId }
//        XCTAssertNotNil(currentPortionIdx, "currentPortionIdx")
//        
//        let nextPortionId = nextPortionId
//        XCTAssertNotNil(nextPortionId, "nextPortionId")
//        XCTAssertNotEqual(nextPortionId, currentPortionIdx, "nextPortionId != currentPortionIdx")
//        
//        sut.barPortionAnimationStatusDict[currentPortionId] = .finish
//        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: {})
//        
//        XCTAssertNotEqual(sut.currentPortionId, currentPortionId, "sut.currentPortionId != currentPortionId")
//        XCTAssertEqual(sut.currentPortionId, nextPortionId, "sut.currentPortionId == nextPortionId")
//        XCTAssertEqual(sut.barPortionAnimationStatusDict[nextPortionId!], .start, "barPortionAnimationStatus")
//    }
//    
//    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_moveToLastPortion_willGoToNextStory() {
//        let currentStoryId = storiesViewModel.currentStoryId
//        var callCount = 0
//        let withoutNextStoryAction: () -> Void = {
//            callCount += 1
//        }
//        
//        while let nextPortionId = nextPortionId {
//            let savedCurrentPortionId = sut.currentPortionId
//            sut.barPortionAnimationStatusDict[sut.currentPortionId] = .finish
//            sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: withoutNextStoryAction)
//            
//            XCTAssertNotEqual(sut.currentPortionId, savedCurrentPortionId, "sut.currentPortionId != savedCurrentPortionId")
//            XCTAssertEqual(sut.currentPortionId, nextPortionId, "sut.currentPortionId == nextPortionId")
//            XCTAssertEqual(sut.barPortionAnimationStatusDict[nextPortionId], .start, "barPortionAnimationStatus")
//            
//            XCTAssertEqual(storiesViewModel.currentStoryId, currentStoryId, "currentStoryId")
//            XCTAssertEqual(callCount, 0, "callCount")
//        }
//        
//        sut.barPortionAnimationStatusDict[sut.currentPortionId] = .finish
//        sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: withoutNextStoryAction)
//        
//        XCTAssertNotEqual(storiesViewModel.currentStoryId, currentStoryId, "storiesViewModel.currentStoryId != currentStoryId")
//        XCTAssertNotNil(nextStoryId, "nextStoryId")
//        XCTAssertEqual(storiesViewModel.currentStoryId, nextStoryId, "storiesViewModel.currentStoryId == nextStoryId")
//        XCTAssertEqual(callCount, 0, "callCount")
//    }
//    
//    func test_performNextBarPortionAnimationWhenCurrentPortionFinished_theCompleteFlowFromBeginningToTheLastPortionOfTheLastStory() {
//        let storyCount = hasPortionStories.count
//        var savedCurrentStoryId = storiesViewModel.currentStoryId
//        var callCount = 0
//        let withoutNextStoryAction: () -> Void = {
//            callCount += 1
//        }
//        
//        for i in 0..<storyCount {
//            while let nextPortionId = nextPortionId {
//                let savedCurrentPortionId = sut.currentPortionId
//                sut.barPortionAnimationStatusDict[sut.currentPortionId] = .finish
//                sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: withoutNextStoryAction)
//                
//                XCTAssertNotEqual(sut.currentPortionId, savedCurrentPortionId, "sut.currentPortionId != savedCurrentPortionId")
//                XCTAssertEqual(sut.currentPortionId, nextPortionId, "sut.currentPortionId == nextPortionId")
//                XCTAssertEqual(sut.barPortionAnimationStatusDict[nextPortionId], .start, "barPortionAnimationStatus")
//                
//                XCTAssertEqual(storiesViewModel.currentStoryId, savedCurrentStoryId, "currentStoryId")
//                XCTAssertEqual(callCount, 0, "callCount")
//            }
//            
//            if i < storyCount - 1 {
//                sut.barPortionAnimationStatusDict[sut.currentPortionId] = .finish
//                sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: withoutNextStoryAction)
//                
//                XCTAssertNotEqual(storiesViewModel.currentStoryId, savedCurrentStoryId, "storiesViewModel.currentStoryId != savedCurrentStoryId")
//                XCTAssertNotNil(nextStoryId, "nextStoryId")
//                XCTAssertEqual(storiesViewModel.currentStoryId, nextStoryId, "storiesViewModel.currentStoryId == nextStoryId")
//                XCTAssertEqual(callCount, 0, "callCount")
//                
//                savedCurrentStoryId = storiesViewModel.currentStoryId
//            } else {
//                sut.barPortionAnimationStatusDict[sut.currentPortionId] = .finish
//                sut.performNextBarPortionAnimationWhenCurrentPortionFinished(withoutNextStoryAction: withoutNextStoryAction)
//                
//                XCTAssertEqual(callCount, 1, "callCount")
//            }
//        }
//    }
//    
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
    
    private func makeSUT() -> (sut: StoryViewModel, stub: ParentStoryViewModelStub) {
        let stub = ParentStoryViewModelStub()
        stub.stories = makeStories()
        
        let sut = StoryViewModel(
            storyId: 0,
            parentViewModel: stub,
            fileManager: DummyFileManager(),
            mediaSaver: DummyMediaSaver()
        )
        return (sut, stub)
    }
    
    private func makeStories() -> [Story] {
        [
            Story(
                id: 0,
                lastUpdate: nil,
                portions: [
                    Portion(
                        id: 0,
                        duration: 1,
                        resourceURL: nil,
                        type: .image
                    )
                ],
                user: User(
                    id: 0,
                    name: "user",
                    avatarURL: nil,
                    isCurrentUser: true
                )
            )
        ]
    }
    
    private class ParentStoryViewModelStub: ObservableObject, ParentStoryViewModel {
        var stories = [Story]()
        var firstCurrentStoryId: Int? = nil
        var currentStoryId = 0
        var shouldCubicRotation = true
        var isNowAtLastStory = false
        var isSameStoryAfterDragging = false
        
        func getIsDraggingPublisher() -> AnyPublisher<Bool, Never> {
            CurrentValueSubject(false).eraseToAnyPublisher()
        }
        
        func moveCurrentStory(to direction: StoryMoveDirection) {}
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
