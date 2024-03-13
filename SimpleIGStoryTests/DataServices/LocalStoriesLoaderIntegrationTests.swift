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
            avatarURL: Bundle.main.url(forResource: "sea1", withExtension: "jpg")!,
            isCurrentUser: true
        )
        return .init(id: 0, lastUpdate: nil, user: user, portions: [])
    }
    
    private func expectedStory1() -> LocalStory {
        let user = LocalUser(
            id: 1,
            name: "sea2",
            avatarURL: Bundle.main.url(forResource: "sea2", withExtension: "jpg")!,
            isCurrentUser: false
        )
        let portions = [
            LocalPortion(
                id: 0,
                resourceURL: Bundle.main.url(forResource: "sea1", withExtension: "jpg")!,
                duration: .defaultStoryDuration,
                type: .image
            ),
            LocalPortion(
                id: 1,
                resourceURL: Bundle.main.url(forResource: "seaVideo", withExtension: "mp4")!,
                duration: 999,
                type: .video
            ),
            LocalPortion(
                id: 2,
                resourceURL: Bundle.main.url(forResource: "sea2", withExtension: "jpg")!,
                duration: 1,
                type: .image
            ),
        ]
        return .init(id: 1, lastUpdate: Date(timeIntervalSince1970: 1645401600), user: user, portions: portions)
    }
}
