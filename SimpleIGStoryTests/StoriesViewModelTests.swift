//
//  StoriesViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 27/04/2022.
//

import XCTest
@testable import Simple_IG_Story

class StoriesViewModelTests: XCTestCase {
    
    var vm: StoriesViewModel!
    
    override func setUpWithError() throws {
        vm = StoriesViewModel()
        
        let expectation = XCTestExpectation(description: "wait 3s for async fetchStories")
        
        Task {
            await vm!.fetchStories()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3)
    }

    override func tearDownWithError() throws {
        vm = nil
    }

    func test_StoriesViewModel_stories_oneAndOnlyOneBelongsToCurrentUser() {
        let stories = vm.stories
        let currentUserStory = stories.first(where: { $0.user.isCurrentUser })
        let currentUserStoryIdx = stories.firstIndex(where: { $0.user.isCurrentUser })
        
        XCTAssertGreaterThan(stories.count, 0)
        XCTAssertNotNil(currentUserStory)
        XCTAssertNotNil(currentUserStoryIdx)
        XCTAssertEqual(vm.yourStoryId, currentUserStory?.id)
        XCTAssertEqual(vm.yourStoryIdx, currentUserStoryIdx)
        XCTAssertEqual(stories.filter({ $0.user.isCurrentUser }).count, 1)
    }
    
    func test_StoriesViewModel_currentStories_shouldContainOnlyOneCurrentUserStory_whenCurrentStoryIdIsSetToCurrentUserStoryId() {
        let currentUserStory = vm.stories.first(where: { $0.user.isCurrentUser })
        XCTAssertNotNil(currentUserStory)
        
        vm.currentStoryId = currentUserStory!.id
        
        XCTAssertEqual(vm.currentStories.count, 1)
        XCTAssertEqual(vm.currentStories.first?.id, currentUserStory?.id)
    }
    
    func test_StoriesViewModel_currentStories_shouldNotContainCurrentUserStory_whenCurrentStoryIdIsNotCurrentUserStoryId() {
        let currentUserStoryId = vm.stories.first(where: { $0.user.isCurrentUser })?.id
        XCTAssertNotNil(currentUserStoryId)
        
        vm.currentStoryId = currentUserStoryId! + 1
        XCTAssertNil(vm.currentStories.first(where: { $0.user.isCurrentUser }))
    }
    
    func test_StoriesViewModel_toggleStoryCamView_setShowStoryCamViewProperly() {
        XCTAssertFalse(vm.showStoryCamView)
        
        vm.toggleStoryCamView()
        
        XCTAssertTrue(vm.showStoryCamView)
        
        vm.toggleStoryCamView()
        
        XCTAssertFalse(vm.showStoryCamView)
    }
    
    func test_StoriesViewModel_showStoryContainer_showContainerShouldBeTrue() {
        guard let firstStoryId = vm.stories.first?.id else {
            XCTFail("Should be at least a current user story in stories array.")
            return
        }
        
        XCTAssertFalse(vm.showContainer)
        
        vm.showStoryContainer(by: firstStoryId)
        
        XCTAssertEqual(vm.currentStoryId, firstStoryId)
        XCTAssertTrue(vm.showContainer)
    }
    
    func test_StoriesViewModel_closeStoryContainer_showContainerShouldBeFalse() {
        guard let firstStoryId = vm.stories.first?.id else {
            XCTFail("Should be at least a current user story in stories array.")
            return
        }
        
        vm.showStoryContainer(by: firstStoryId)
        
        XCTAssertTrue(vm.showContainer)
        
        vm.closeStoryContainer()
        
        XCTAssertFalse(vm.showContainer)
    }
    
    func test_StoriesViewModel_tapStoryIcon_toggleStoryCamViewIfStoryNoPortionAndBelongsToCurrentUser() {
        guard let currentUserStory = vm.stories.first(where: { $0.user.isCurrentUser && !$0.hasPortion }) else {
            XCTFail("Should be at least a current user story in stories array.")
            return
        }
        
        XCTAssertFalse(currentUserStory.hasPortion)
        
        let showStoryCamView = vm.showStoryCamView
        vm.tapStoryIcon(with: currentUserStory.id)
        
        XCTAssertNotEqual(vm.showStoryCamView, showStoryCamView)
    }
    
    func test_StoriesViewModel_tapStoryIcon_showStoryContainerIfStoryHasPortion() {
        guard let hasPortionStory = vm.stories.first(where: { $0.hasPortion }) else {
            XCTFail("Make sure one story has portion in testing data.")
            return
        }
        
        vm.tapStoryIcon(with: hasPortionStory.id)
        
        XCTAssertEqual(vm.currentStoryId, hasPortionStory.id)
        XCTAssertTrue(vm.showContainer)
    }
    
    func test_StoriesViewModel_dragStoryContainer_isDraggingShouldBeTrue_storyIdBeforeDraggedShouldEqualCurrentStoryId() {
        let tempCurrentStoryId = vm.currentStoryId
        vm.currentStoryId = tempCurrentStoryId + 1
        
        XCTAssertFalse(vm.isDragging)
        
        vm.dragStoryContainer()
        
        XCTAssertTrue(vm.isDragging)
        XCTAssertEqual(vm.storyIdBeforeDragged, tempCurrentStoryId + 1)
        XCTAssertNotEqual(vm.storyIdBeforeDragged, tempCurrentStoryId)
    }
}
