//
//  FileDataClientTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import XCTest
@testable import Simple_IG_Story

final class FileDataClient: DataClient {
    private let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    enum Error: Swift.Error {
        case empty
    }
    
    func fetch() async throws -> Data {
        let data = try Data(contentsOf: url)
        guard !data.isEmpty else {
            throw Error.empty
        }
        
        return data
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
    
    func test_fetch_deliversErrorWhenEmptyFile() async {
        let sut = FileDataClient(url: emptyFileURL())
        
        do {
            _ = try await sut.fetch()
            XCTFail("Should be an error")
        } catch {}
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
