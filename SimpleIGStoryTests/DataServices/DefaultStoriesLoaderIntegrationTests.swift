//
//  DefaultStoriesLoaderIntegrationTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import XCTest
@testable import Simple_IG_Story

final class DefaultStoriesLoaderIntegrationTests: XCTestCase {
    func test_load_deliversDataCorrectly() async throws {
        let client = FileDataClient(url: validJsonURL(currentClass: Self.self))
        let sut = DefaultStoriesLoader(client: client)
        
        let receivedStories = try await sut.load()
        
        XCTAssertEqual(receivedStories, expectedStories())
    }
    
    // MARK: - Helpers
    
    private func expectedStories() -> [Story] {
        [expectedStory0(), expectedStory1()]
    }
    
    private func expectedStory0() -> Story {
        let user = User(
            id: 0,
            name: "sea1",
            avatarURL: avatarURLFor("sea1"),
            isCurrentUser: true
        )
        return Story(id: 0, lastUpdate: nil, user: user, portions: [])
    }
    
    private func expectedStory1() -> Story {
        let user = User(
            id: 1,
            name: "sea2",
            avatarURL: avatarURLFor("sea2"),
            isCurrentUser: false
        )
        let portions = [
            Portion(
                id: 0,
                resourceURL: resourceURLFor("sea1", type: "image"),
                duration: .defaultStoryDuration,
                type: .image
            ),
            Portion(
                id: 1,
                resourceURL: resourceURLFor("seaVideo", type: "video"),
                duration: 999,
                type: .video
            ),
            Portion(
                id: 2,
                resourceURL: resourceURLFor("sea2", type: "image"),
                duration: 1,
                type: .image
            ),
        ]
        return Story(id: 1, lastUpdate: Date(timeIntervalSince1970: 1645401600), user: user, portions: portions)
    }
}
