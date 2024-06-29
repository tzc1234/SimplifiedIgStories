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
        let sut = FileDataClient(url: invalidJsonURL())
        
        await assertThrowsError(_ = try await sut.fetch())
    }
    
    func test_fetch_deliversErrorWhenEmptyFile() async {
        let sut = FileDataClient(url: emptyFileURL())
        
        await assertThrowsError(_ = try await sut.fetch())
    }
    
    func test_fetch_deliversDataWhenValidFile() async throws {
        let sut = FileDataClient(url: validJSONURL(currentClass: Self.self))
        
        let receivedData = try await sut.fetch()
        
        XCTAssertFalse(receivedData.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func invalidJsonURL(file: StaticString = #filePath) -> URL {
        FileManager.default.temporaryDirectory
    }
    
    private func emptyFileURL() -> URL {
        bundle(currentClass: Self.self).url(forResource: "empty.json", withExtension: nil)!
    }
}
