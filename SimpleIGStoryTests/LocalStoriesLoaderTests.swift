//
//  LocalStoriesLoaderTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import XCTest

final class LocalStoriesLoader {
    private let client: DataClient
    
    init(client: DataClient) {
        self.client = client
    }
    
    enum Error: Swift.Error {
        case notFound
    }

    func load() async throws {
        do {
            try await client.fetch()
        } catch {
            throw Error.notFound
        }
    }
}

protocol DataClient {
    func fetch() async throws
}

final class DataClientSpy: DataClient {
    private(set) var requestCallCount = 0
    
    private var stubs = [Result<Void, Error>]()
    
    init(stubs: [Result<Void, Error>]) {
        self.stubs = stubs
    }
    
    func fetch() async throws {
        requestCallCount += 1
        try stubs.removeLast().get()
    }
}

final class LocalStoriesLoaderTests: XCTestCase {
    func test_init_doesNotNotifyClient() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.requestCallCount, 0)
    }
    
    func test_load_requestsFromClient() async throws {
        let (sut, client) = makeSUT(stubs: [.success(())])
        
        try await sut.load()
        
        XCTAssertEqual(client.requestCallCount, 1)
    }
    
    func test_load_deliversNotFoundErrorOnClientError() async {
        let (sut, client) = makeSUT(stubs: [.failure(anyNSError())])
        
        do {
            try await sut.load()
            XCTFail("Should be an error")
        } catch {
            XCTAssertEqual(error as? LocalStoriesLoader.Error, .notFound)
        }
    }
    
    // MAKE: - Helpers
    
    private func makeSUT(stubs: [Result<Void, Error>] = [],
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
}
