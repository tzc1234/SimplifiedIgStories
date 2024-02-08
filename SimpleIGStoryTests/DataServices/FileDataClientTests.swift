//
//  FileDataClientTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import XCTest
@testable import Simple_IG_Story

final class FileDataClientTests: XCTestCase {
    func test_fetch_deliversErrorWhenInvalidURL() async {
        let sut = FileDataClient(url: invalidURL())
        
        await assertThrowsError(_ = try await sut.fetch())
    }
    
    func test_fetch_deliversErrorWhenEmptyFile() async {
        let sut = FileDataClient(url: emptyFileURL())
        
        await assertThrowsError(_ = try await sut.fetch())
    }
    
    func test_fetch_deliversDataWhenValidFile() async throws {
        let sut = FileDataClient(url: validURL())
        
        let receivedData = try await sut.fetch()
        
        XCTAssertFalse(receivedData.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func invalidURL(file: StaticString = #filePath) -> URL {
        FileManager.default.temporaryDirectory
    }
    
    private func emptyFileURL() -> URL {
        bundle().url(forResource: "empty.json", withExtension: nil)!
    }
    
    private func validURL(file: StaticString = #filePath) -> URL {
        bundle().url(forResource: "valid.json", withExtension: nil)!
    }
    
    private func bundle() -> Bundle {
        Bundle(for: Self.self)
    }
}
