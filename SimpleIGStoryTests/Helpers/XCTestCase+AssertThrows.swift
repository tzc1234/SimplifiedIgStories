//
//  XCTestCase+AssertThrows.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 08/02/2024.
//

import XCTest

extension XCTestCase {
    func assertThrowsError(_ expression: @autoclosure () async throws -> Void,
                           _ message: String = "",
                           file: StaticString = #filePath,
                           line: UInt = #line,
                           _ errorHandler: (Error) -> Void = { _ in }) async {
        do {
            try await expression()
            XCTFail(message, file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}
