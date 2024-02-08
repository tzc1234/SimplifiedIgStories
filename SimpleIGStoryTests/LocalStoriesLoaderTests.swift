//
//  LocalStoriesLoaderTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import XCTest

struct LocalStory: Equatable {
    
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
        
    }

    func load() async throws -> [LocalStory] {
        guard let data = try? await client.fetch() else {
            throw Error.notFound
        }
        
        guard let _ = try? JSONDecoder().decode([DecodableStory].self, from: data) else {
            throw Error.invalidData
        }
        
        return []
    }
}

protocol DataClient {
    func fetch() async throws -> Data
}

final class DataClientSpy: DataClient {
    typealias Stub = Result<Data, Error>
    
    private(set) var requestCallCount = 0
    
    private var stubs = [Stub]()
    
    init(stubs: [Stub]) {
        self.stubs = stubs
    }
    
    func fetch() async throws -> Data {
        requestCallCount += 1
        return try stubs.removeLast().get()
    }
}

final class LocalStoriesLoaderTests: XCTestCase {
    func test_init_doesNotNotifyClient() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.requestCallCount, 0)
    }
    
    func test_load_deliversNotFoundErrorOnClientError() async {
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError())])
        
        do {
            _ = try await sut.load()
            XCTFail("Should be an error")
        } catch {
            XCTAssertEqual(error as? LocalStoriesLoader.Error, .notFound)
        }
    }
    
    func test_load_deliversInvalidDataErrorWhileReceivedInvalidData() async {
        let invalidData = Data("invalid".utf8)
        let (sut, _) = makeSUT(stubs: [.success(invalidData)])
        
        do {
            _ = try await sut.load()
            XCTFail("Should be an error")
        } catch {
            XCTAssertEqual(error as? LocalStoriesLoader.Error, .invalidData)
        }
    }
    
    func test_load_deliversEmptyStoriesWhileReceivedEmptyJSON() async throws {
        let (sut, _) = makeSUT(stubs: [.success(emptyStoriesData())])
        
        let receivedStories = try await sut.load()
        
        XCTAssertEqual(receivedStories, [])
    }
    
    // MAKE: - Helpers
    
    private func makeSUT(stubs: [DataClientSpy.Stub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalStoriesLoader, client: DataClientSpy) {
        let client = DataClientSpy(stubs: stubs)
        let sut = LocalStoriesLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "any", code: 0)
    }
    
    private func emptyStoriesData() -> Data {
        let json: [[String: Any]] = []
        return try! JSONSerialization.data(withJSONObject: json)
    }
}
