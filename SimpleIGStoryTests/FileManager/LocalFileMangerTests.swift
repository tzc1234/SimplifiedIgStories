//
//  LocalFileMangerTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 12/03/2024.
//

import XCTest
@testable import Simple_IG_Story

final class LocalFileMangerTests: XCTestCase {
    func test_getImage_doesNotDeliverImageWhenNoImageFound() {
        let sut = LocalFileManager()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
        
        let image = sut.getImage(for: url)
        
        XCTAssertNil(image)
    }
}
