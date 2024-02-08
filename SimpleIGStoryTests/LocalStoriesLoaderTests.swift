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

    func load() {
        client.fetch()
    }
}

protocol DataClient {
    func fetch()
}

final class DataClientSpy: DataClient {
    private(set) var requestCallCount = 0
    
    func fetch() {
        requestCallCount += 1
    }
}

final class LocalStoriesLoaderTests: XCTestCase {
    func test_init_doesNotNotifyClient() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.requestCallCount, 0)
    }
    
    func test_load_requestsFromClient() {
        let (sut, client) = makeSUT()
        
        sut.load()
        
        XCTAssertEqual(client.requestCallCount, 1)
    }
    
    // MAKE: - Helpers
    
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalStoriesLoader, client: DataClientSpy) {
        let client = DataClientSpy()
        let sut = LocalStoriesLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
}
