//
//  StoryPreviewViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 04/07/2024.
//

import XCTest
@testable import Simple_IG_Story

final class StoryPreviewViewModelTests: XCTestCase {
    func test_init_doesNotNotifyMediaSaver() {
        let (_, mediaSaver) = makeSUT()
        
        XCTAssertEqual(mediaSaver.saveImageDataCallCount, 0)
        XCTAssertEqual(mediaSaver.saveVideoCallCount, 0)
    }
    
    // MARK: Helpers
    
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: StoryPreviewViewModel, mediaSaver: MediaSaverSpy) {
        let mediaSaver = MediaSaverSpy()
        let sut = StoryPreviewViewModel(mediaSaver: mediaSaver)
        trackForMemoryLeaks(mediaSaver, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, mediaSaver)
    }
}
