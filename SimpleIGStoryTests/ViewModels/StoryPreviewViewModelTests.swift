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
        let (sut, mediaSaver) = makeSUT()
        
        XCTAssertEqual(sut.message, "")
        XCTAssertEqual(mediaSaver.saveImageDataCallCount, 0)
        XCTAssertEqual(mediaSaver.saveVideoCallCount, 0)
    }
    
    @MainActor
    func test_saveToAlbumImage_deliversNoPermissionMessageOnNoPermissionError() async {
        let (sut, mediaSaver) = makeSUT(saveImageDataStub: { throw MediaSaverError.noPermission })
        
        await sut.saveToAlbum(image: anyUIImage())
        
        XCTAssertEqual(mediaSaver.saveImageDataCallCount, 1)
        XCTAssertEqual(sut.message, "Couldn't save. No add photo permission.")
    }
    
    @MainActor
    func test_saveToAlbumImage_deliversSaveFailedMessageOnAnyErrors() async {
        let (sut, mediaSaver) = makeSUT(saveImageDataStub: { throw anyNSError() })
        
        await sut.saveToAlbum(image: anyUIImage())
        
        XCTAssertEqual(mediaSaver.saveImageDataCallCount, 1)
        XCTAssertEqual(sut.message, "Save failed.")
    }
    
    @MainActor
    func test_saveToAlbumImage_deliversSavedMessageOnSaveSuccessfully() async {
        let (sut, mediaSaver) = makeSUT()
        
        await sut.saveToAlbum(image: anyUIImage())
        
        XCTAssertEqual(mediaSaver.saveImageDataCallCount, 1)
        XCTAssertEqual(sut.message, "Saved.")
    }
    
    @MainActor
    func test_saveToAlbumVideoURL_deliversNoPermissionMessageOnNoPermissionError() async {
        let (sut, mediaSaver) = makeSUT(saveVideoStub: { throw MediaSaverError.noPermission })
        
        await sut.saveToAlbum(videoURL: anyVideoURL())
        
        XCTAssertEqual(mediaSaver.saveVideoCallCount, 1)
        XCTAssertEqual(sut.message, "Couldn't save. No add photo permission.")
    }
    
    @MainActor
    func test_saveToAlbumVideoURL_deliversNoPermissionMessageOnAnyError() async {
        let (sut, mediaSaver) = makeSUT(saveVideoStub: { throw anyNSError() })
        
        await sut.saveToAlbum(videoURL: anyVideoURL())
        
        XCTAssertEqual(mediaSaver.saveVideoCallCount, 1)
        XCTAssertEqual(sut.message, "Save failed.")
    }
    
    @MainActor
    func test_saveToAlbumVideoURL_deliversSavedMessageOnSaveSuccessfully() async {
        let (sut, mediaSaver) = makeSUT()
        
        await sut.saveToAlbum(videoURL: anyVideoURL())
        
        XCTAssertEqual(mediaSaver.saveVideoCallCount, 1)
        XCTAssertEqual(sut.message, "Saved.")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(saveImageDataStub: @escaping () async throws -> Void = {},
                         saveVideoStub: @escaping () async throws -> Void = {},
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: StoryPreviewViewModel, mediaSaver: MediaSaverSpy) {
        let mediaSaver = MediaSaverSpy(saveImageDataStub: saveImageDataStub, saveVideoStub: saveVideoStub)
        let sut = StoryPreviewViewModel(mediaSaver: mediaSaver)
        trackForMemoryLeaks(mediaSaver, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, mediaSaver)
    }
}
