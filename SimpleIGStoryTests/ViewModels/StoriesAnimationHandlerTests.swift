//
//  StoriesAnimationHandlerTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 22/03/2024.
//

import XCTest
@testable import Simple_IG_Story

final class StoriesAnimationHandlerTests: XCTestCase {
    func test_init_deliversStoriesAsStoriesHolderStories() {
        let stories = [makeStory(portions: [makePortion(id: 0)])]
        let sut = makeSUT(stories: stories)
        
        XCTAssertEqual(sut.stories, stories)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(stories: [Story] = []) -> StoriesAnimationHandler {
        let storiesHolder = StoriesHolderStub(stories: stories)
        let sut = StoriesAnimationHandler(storiesHolder: storiesHolder)
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
