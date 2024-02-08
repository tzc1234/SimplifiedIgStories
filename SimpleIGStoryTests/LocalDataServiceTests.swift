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
        let client = DataClientSpy()
        let _ = LocalDataService(client: client)
        
        XCTAssertTrue(client.messages.isEmpty)
    }
}
