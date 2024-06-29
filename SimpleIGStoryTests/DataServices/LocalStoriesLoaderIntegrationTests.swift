//
//  LocalStoriesLoaderIntegrationTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import XCTest
@testable import Simple_IG_Story

final class LocalStoriesLoaderIntegrationTests: XCTestCase {
    func test_load_deliversDataCorrectly() async throws {
        let client = FileDataClient(url: validJsonURL(currentClass: Self.self))
        let sut = LocalStoriesLoader(client: client)
        
        let receivedStories = try await sut.load()
        
        XCTAssertEqual(receivedStories, expectedStories())
    }
    
    // MARK: - Helpers
    
    private func expectedStories() -> [LocalStory] {
        [expectedStory0(), expectedStory1()]
    }
    
    private func expectedStory0() -> LocalStory {
        let user = LocalUser(
            id: 0,
            name: "sea1",
            avatarURL: avatarURLFor("sea1"),
            isCurrentUser: true
        )
        return LocalStory(id: 0, lastUpdate: nil, user: user, portions: [])
    }
    
    private func expectedStory1() -> LocalStory {
        let user = LocalUser(
            id: 1,
            name: "sea2",
            avatarURL: avatarURLFor("sea2"),
            isCurrentUser: false
        )
        let portions = [
            LocalPortion(
                id: 0,
                resourceURL: resourceURLFor("sea1", type: "image"),
                duration: .defaultStoryDuration,
                type: .image
            ),
            LocalPortion(
                id: 1,
                resourceURL: resourceURLFor("seaVideo", type: "video"),
                duration: 999,
                type: .video
            ),
            LocalPortion(
                id: 2,
                resourceURL: resourceURLFor("sea2", type: "image"),
                duration: 1,
                type: .image
            ),
        ]
        return LocalStory(id: 1, lastUpdate: Date(timeIntervalSince1970: 1645401600), user: user, portions: portions)
    }
}
