//
//  FileDataClientTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import XCTest
@testable import Simple_IG_Story

final class FileDataClient: DataClient {
    init(url: URL) {
        
    }
    
    func fetch() async throws -> Data {
        throw NSError(domain: "any", code: 0)
    }
}

final class FileDataClientTests: XCTestCase {
    func test_fetch_deliversErrorWhenInvalidURL() async {
        let sut = FileDataClient(url: invalidURL())
        
        do {
            _ = try await sut.fetch()
            XCTFail("Should be an error")
        } catch {}
    }
    
    // MARK: - Helpers
    
    private func invalidURL(file: StaticString = #filePath) -> URL {
        URL(fileURLWithPath: String(describing: file)).deletingLastPathComponent()
    }
}
