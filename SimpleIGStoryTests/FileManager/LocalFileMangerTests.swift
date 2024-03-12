//
//  LocalFileMangerTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 12/03/2024.
//

import XCTest
@testable import Simple_IG_Story

final class LocalFileMangerTests: XCTestCase {
    func test_getImage_doesNotDeliverImageWhenNoImage() {
        let sut = LocalFileManager()
        
        let image = sut.getImage(for: imageFileURL())
        
        XCTAssertNil(image)
    }
    
    func test_getImageTwice_ensuresNoSideEffectsWhenNoImage() {
        let sut = LocalFileManager()
        let url = imageFileURL()
        
        let firstImage = sut.getImage(for: url)
        let lastImage = sut.getImage(for: url)
        
        XCTAssertNil(firstImage)
        XCTAssertNil(lastImage)
    }
    
    // MARK: - Helpers
    
    private func imageFileURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("test.jpg")
    }
}
