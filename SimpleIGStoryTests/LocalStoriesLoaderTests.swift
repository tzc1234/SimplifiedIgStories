//
//  LocalStoriesLoaderTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import XCTest

struct LocalStory: Equatable {
    let id: Int
    let lastUpdate: Date?
    let user: LocalUser
}

struct LocalUser: Equatable {
    let id: Int
    let name: String
    let avatar: String
    let isCurrentUser: Bool
}

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
        
        var local: LocalStory {
            .init(id: id, lastUpdate: lastUpdate.map(Date.init(timeIntervalSince1970:)), user: user.local)
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

protocol DataClient {
    func fetch() async throws -> Data
}

final class DataClientStub: DataClient {
    typealias Stub = Result<Data, Error>
    
    private var stubs = [Stub]()
    
    init(stubs: [Stub]) {
        self.stubs = stubs
    }
    
    func fetch() async throws -> Data {
        return try stubs.removeLast().get()
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
                userId: 0,
                userName: "user0",
                avatar: "avatar0",
                isCurrentUser: true
            ),
            makeStory(
                id: 1,
                lastUpdate: 1645401600,
                userId: 1,
                userName: "user1",
                avatar: "avatar1",
                isCurrentUser: true
            )
        ]
        let data = stories.map(\.json).toData()
        let local = stories.map(\.local)
        let sut = makeSUT(stubs: [.success(data)])
        
        let receivedStories = try await sut.load()
        
        XCTAssertEqual(receivedStories, local)
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
                           userId: Int,
                           userName: String,
                           avatar: String,
                           isCurrentUser: Bool) -> (json: [String: Any], local: LocalStory) {
        let json: [String: Any] = [
            "id": id,
            "lastUpdate": lastUpdate,
            "user": [
                "id": userId,
                "name": userName,
                "avatar": avatar,
                "isCurrentUser": isCurrentUser
            ]
        ].compactMapValues { $0 }
        
        let user = LocalUser(id: userId, name: userName, avatar: avatar, isCurrentUser: isCurrentUser)
        let local = LocalStory(id: id, lastUpdate: lastUpdate.map(Date.init(timeIntervalSince1970:)), user: user)
        
        return (json, local)
    }
}

extension [[String: Any]] {
    func toData() -> Data {
        try! JSONSerialization.data(withJSONObject: self)
    }
}
