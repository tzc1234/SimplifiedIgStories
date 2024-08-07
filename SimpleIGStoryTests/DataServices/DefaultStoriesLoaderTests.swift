//
//  DefaultStoriesLoaderTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import XCTest
@testable import Simple_IG_Story

final class DefaultStoriesLoaderTests: XCTestCase {
    func test_load_deliversNotFoundErrorOnClientError() async {
        let sut = makeSUT(stub: .failure(anyNSError()))
        
        await assertThrowsError(_ = try await sut.load()) { error in
            XCTAssertEqual(error as? StoriesLoaderError, .notFound)
        }
    }
    
    func test_load_deliversInvalidDataErrorWhileReceivedInvalidData() async {
        let invalidData = Data("invalid".utf8)
        let sut = makeSUT(stub: .success(invalidData))
        
        await assertThrowsError(_ = try await sut.load()) { error in
            XCTAssertEqual(error as? StoriesLoaderError, .invalidData)
        }
    }
    
    func test_load_deliversEmptyStoriesWhileReceivedEmptyJSON() async throws {
        let sut = makeSUT(stub: .success(emptyStoriesJSONData()))
        
        let receivedStories = try await sut.load()
        
        XCTAssertEqual(receivedStories, [])
    }
    
    func test_load_deliversStoriesWhileReceivedValidData() async throws {
        let stories = [
            makeStory(
                id: 0,
                lastUpdate: nil,
                user: UserInput(id: 0, name: "user0", avatar: "sea1", isCurrentUser: true),
                portions: []
            ),
            makeStory(
                id: 1,
                lastUpdate: 1645401600,
                user: UserInput(id: 1, name: "user1", avatar: "sea2", isCurrentUser: false),
                portions: [
                    PortionInput(
                        id: 0,
                        resource: "forest1",
                        duration: nil,
                        type: "image"
                    ),
                    PortionInput(
                        id: 1,
                        resource: "forestVideo",
                        duration: 999,
                        type: "video"
                    ),
                    PortionInput(
                        id: 2,
                        resource: "forest2",
                        duration: nil,
                        type: "unknown"
                    ),
                ]
            )
        ]
        let validData = stories.map(\.json).toData()
        let sut = makeSUT(stub: .success(validData))
        
        let receivedStories = try await sut.load()
        
        let expectedStories = stories.map(\.model)
        XCTAssertEqual(receivedStories, expectedStories)
    }
    
    // MAKE: - Helpers
    
    private func makeSUT(stub: DataClientStub.Stub,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> DefaultStoriesLoader {
        let client = DataClientStub(stub: stub)
        let sut = DefaultStoriesLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func emptyStoriesJSONData() -> Data {
        let json: [JSON] = []
        return json.toData()
    }
    
    private func makeStory(id: Int,
                           lastUpdate: TimeInterval?,
                           user: UserInput,
                           portions: [PortionInput]) -> (json: JSON, model: Story) {
        let json: JSON = [
            "id": id,
            "lastUpdate": lastUpdate as Any?,
            "user": user.json,
            "portions": portions.map(\.json)
        ]
        .compactMapValues { $0 }
        
        let model = Story(
            id: id,
            lastUpdate: lastUpdate.map(Date.init(timeIntervalSince1970:)),
            user: user.model,
            portions: portions.map(\.model)
        )
        
        return (json, model)
    }
    
    private struct UserInput {
        let id: Int
        let name: String
        let avatar: String
        let isCurrentUser: Bool
        
        var json: JSON {
            [
                "id": id,
                "name": name,
                "avatar": avatar,
                "isCurrentUser": isCurrentUser
            ]
        }
        
        var model: User {
            User(
                id: id,
                name: name,
                avatarURL: avatarURLFor(avatar),
                isCurrentUser: isCurrentUser
            )
        }
    }
    
    private struct PortionInput {
        let id: Int
        let resource: String
        let duration: Double?
        let type: String
        
        var json: JSON {
            [
                "id": id,
                "resource": resource,
                "duration": duration as Any?,
                "type": type
            ]
            .compactMapValues { $0 }
        }
        
        var model: Portion {
            Portion(
                id: id,
                resourceURL: resourceURLFor(resource, type: type),
                duration: duration ?? .defaultStoryDuration,
                type: ResourceType(rawValue: type) ?? .image
            )
        }
    }
}

private extension [JSON] {
    func toData() -> Data {
        try! JSONSerialization.data(withJSONObject: self)
    }
}
