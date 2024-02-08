//
//  LocalDataServiceTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import XCTest

final class LocalDataService {
    init(client: DataClient) {
        
    }
}

protocol DataClient {}

final class DataClientSpy: DataClient {
    private(set) var messages = [Any]()
}

final class LocalDataServiceTests: XCTestCase {
    func test_init_doesNotNotifyClient() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.messages.isEmpty)
    }
    
    // MAKE: - Helpers
    
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalDataService, client: DataClientSpy) {
        let client = DataClientSpy()
        let sut = LocalDataService(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
}
