//
//  LocalStoriesLoaderTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import XCTest
@testable import Simple_IG_Story

final class LocalStoriesLoader {
    private let client: DataClient
    
    init(client: DataClient) {
        self.client = client
    }
    
    enum Error: Swift.Error {
        case notFound
        case invalidData
    }
    
    private struct DecodableStory: Decodable {
        let id: Int
        let lastUpdate: TimeInterval?
        let user: User
        let portions: [Portion]
        
        var local: LocalStory {
            .init(
                id: id,
                lastUpdate: lastUpdate.map(Date.init(timeIntervalSince1970:)),
                user: user.local,
                portions: portions.map(\.local)
            )
        }
        
        struct User: Decodable {
            let id: Int
            let name: String
            let avatar: String
            let isCurrentUser: Bool
            
            var local: LocalUser {
                .init(id: id, name: name, avatar: avatar, isCurrentUser: isCurrentUser)
            }
        }
        
        struct Portion: Decodable {
            let id: Int
            let resource: String
            let duration: Double?
            let type: String
            
            var local: LocalPortion {
                .init(
                    id: id,
                    resource: resource,
                    duration: duration ?? .defaultStoryDuration,
                    type: .init(rawValue: type) ?? .image
                )
            }
        }
    }

    func load() async throws -> [LocalStory] {
        guard let data = try? await client.fetch() else {
            throw Error.notFound
        }
        
        guard let stories = try? JSONDecoder().decode([DecodableStory].self, from: data) else {
            throw Error.invalidData
        }
        
        return stories.map(\.local)
    }
}

final class LocalStoriesLoaderTests: XCTestCase {
    func test_load_deliversNotFoundErrorOnClientError() async {
        let sut = makeSUT(stubs: [.failure(anyNSError())])
        
        do {
            _ = try await sut.load()
            XCTFail("Should be an error")
        } catch {
            XCTAssertEqual(error as? LocalStoriesLoader.Error, .notFound)
        }
    }
    
    func test_load_deliversInvalidDataErrorWhileReceivedInvalidData() async {
        let invalidData = Data("invalid".utf8)
        let sut = makeSUT(stubs: [.success(invalidData)])
        
        do {
            _ = try await sut.load()
            XCTFail("Should be an error")
        } catch {
            XCTAssertEqual(error as? LocalStoriesLoader.Error, .invalidData)
        }
    }
    
    func test_load_deliversEmptyStoriesWhileReceivedEmptyJSON() async throws {
        let sut = makeSUT(stubs: [.success(emptyStoriesData())])
        
        let receivedStories = try await sut.load()
        
        XCTAssertEqual(receivedStories, [])
    }
    
    func test_load_deliversStoriesWhileReceivedValidJSON() async throws {
        let stories = [
            makeStory(
                id: 0,
                lastUpdate: nil,
                user: .init(id: 0, name: "user0", avatar: "avatar0", isCurrentUser: true),
                portions: []
            ),
            makeStory(
                id: 1,
                lastUpdate: 1645401600,
                user: .init(id: 1, name: "user1", avatar: "avatar1", isCurrentUser: false),
                portions: [
                    .init(id: 0, resource: "resource0", duration: nil, type: "image"),
                    .init(id: 1, resource: "resource1", duration: 999, type: "video"),
                ]
            )
        ]
        let data = stories.map(\.json).toData()
        let sut = makeSUT(stubs: [.success(data)])
        
        let receivedStories = try await sut.load()
        
        let models = stories.map(\.model)
        XCTAssertEqual(receivedStories, models)
    }
    
    // MAKE: - Helpers
    
    private func makeSUT(stubs: [DataClientStub.Stub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> LocalStoriesLoader {
        let client = DataClientStub(stubs: stubs)
        let sut = LocalStoriesLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "any", code: 0)
    }
    
    private func emptyStoriesData() -> Data {
        let json: [[String: Any]] = []
        return json.toData()
    }
    
    private func makeStory(id: Int,
                           lastUpdate: TimeInterval?,
                           user: UserInput,
                           portions: [PortionInput]) -> (json: [String: Any], model: LocalStory) {
        let json: [String: Any] = [
            "id": id,
            "lastUpdate": lastUpdate as Any?,
            "user": user.json,
            "portions": portions.map(\.json)
        ].compactMapValues { $0 }
        
        let model = LocalStory(
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
        
        var json: [String: Any] {
            [
                "id": id,
                "name": name,
                "avatar": avatar,
                "isCurrentUser": isCurrentUser
            ]
        }
        
        var model: LocalUser {
            .init(id: id, name: name, avatar: avatar, isCurrentUser: isCurrentUser)
        }
    }
    
    private struct PortionInput {
        let id: Int
        let resource: String
        let duration: Double?
        let type: String
        
        var json: [String: Any] {
            [
                "id": id,
                "resource": resource,
                "duration": duration as Any?,
                "type": type
            ].compactMapValues { $0 }
        }
        
        var model: LocalPortion {
            .init(
                id: id,
                resource: resource,
                duration: duration ?? .defaultStoryDuration,
                type: .init(rawValue: type) ?? .image
            )
        }
    }
    
    final private class DataClientStub: DataClient {
        typealias Stub = Result<Data, Error>
        
        private var stubs = [Stub]()
        
        init(stubs: [Stub]) {
            self.stubs = stubs
        }
        
        func fetch() async throws -> Data {
            return try stubs.removeLast().get()
        }
    }
}

extension [[String: Any]] {
    func toData() -> Data {
        try! JSONSerialization.data(withJSONObject: self)
    }
}
