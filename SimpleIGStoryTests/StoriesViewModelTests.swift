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
        vm = StoriesViewModel(localFileManager: LocalFileManager())
        
        let expectation = XCTestExpectation(description: "wait async fetchStories")
        
        Task {
            await vm.fetchStories()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.5)
    }

    override func tearDownWithError() throws {
        vm = nil
    }

    func test_stories_ensureOneCurrentUserInStories() {
        let stories = vm.stories
        let currentUserStory = stories.first(where: { $0.user.isCurrentUser })
        let currentUserStoryIdx = stories.firstIndex(where: { $0.user.isCurrentUser })
        
        XCTAssertNotNil(currentUserStory, "currentUserStory")
        XCTAssertNotNil(currentUserStoryIdx, "currentUserStoryIdx")
        XCTAssertEqual(vm.yourStoryId, currentUserStory?.id, "yourStoryId == currentUserStory")
        XCTAssertEqual(vm.yourStoryIdx, currentUserStoryIdx, "yourStoryIdx == currentUserStoryIdx")
    }
    
    func test_currentStories_shouldContainOnlyOneCurrentUserStory_whenCurrentStoryIdIsSetToCurrentUserStoryId() {
        let currentUserStoryId = vm.stories.first(where: { $0.user.isCurrentUser })?.id
        XCTAssertNotNil(currentUserStoryId, "currentUserStoryId")
        
        vm.setCurrentStoryId(currentUserStoryId!)
        
        XCTAssertEqual(vm.currentStoryId, currentUserStoryId!, "currentStoryId == currentUserStoryId")
        XCTAssertEqual(vm.currentStories.count, 1, "currentStories.count == 1")
        XCTAssertEqual(vm.currentStories.first?.id, currentUserStoryId, "currentStories.first.id == currentUserStoryId")
    }
    
    func test_currentStories_shouldNotContainCurrentUserStory_whenCurrentStoryIdIsNotCurrentUserStoryId() {
        let nonCurrentUserStroyId = vm.stories.first(where: { !$0.user.isCurrentUser })?.id
        XCTAssertNotNil(nonCurrentUserStroyId, "nonCurrentUserStroyId")
        
        vm.setCurrentStoryId(nonCurrentUserStroyId!)
        
        XCTAssertEqual(vm.currentStoryId, nonCurrentUserStroyId!, "currentStoryId == nonCurrentUserStroyId")
        XCTAssertEqual(vm.currentStories.filter { $0.user.isCurrentUser }.count, 0, "currentStories")
    }
    
}
