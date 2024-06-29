//
//  LocalMediaSaverTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 09/02/2024.
//

import XCTest
@testable import Simple_IG_Story

final class LocalMediaSaverTests: XCTestCase {
    func test_saveImageData_deliversNoPermissionErrorOnStoreNoPermissionError() async {
        let (sut, _) = makeSUT(stub: .failure(.noPermission))
        
        await assertThrowsError(try await sut.saveImageData(anyImageData())) { error in
            XCTAssertEqual(error as? MediaSaverError, .noPermission)
        }
    }
    
    func test_saveImageData_deliversFailedErrorWhenStoreFailedOnSave() async {
        let (sut, _) = makeSUT(stub: .failure(.failed))
        
        await assertThrowsError(try await sut.saveImageData(anyImageData())) { error in
            XCTAssertEqual(error as? MediaSaverError, .failed)
        }
    }
    
    func test_saveImageData_saveSuccessfullyIntoStore() async throws {
        let (sut, store) = makeSUT(stub: .success(()))
        let imageData = UIImage.make(withColor: .red).pngData()!
        
        try await sut.saveImageData(imageData)
        
        XCTAssertEqual(store.savedImageData, [imageData])
    }
    
    func test_saveVideo_deliversNoPermissionErrorOnStoreNoPermissionError() async {
        let (sut, _) = makeSUT(stub: .failure(.noPermission))
        
        await assertThrowsError(try await sut.saveVideo(by: anyVideoURL())) { error in
            XCTAssertEqual(error as? MediaSaverError, .noPermission)
        }
    }
    
    func test_saveVideo_deliversFailedErrorWhenStoreFailedOnSave() async {
        let (sut, _) = makeSUT(stub: .failure(.failed))
        
        await assertThrowsError(try await sut.saveVideo(by: anyVideoURL())) { error in
            XCTAssertEqual(error as? MediaSaverError, .failed)
        }
    }
    
    func test_saveVideo_saveSuccessfullyIntoStore() async throws {
        let (sut, store) = makeSUT(stub: .success(()))
        let videoURL = URL(string: "file://video.mp4")!
        
        try await sut.saveVideo(by: videoURL)
        
        XCTAssertEqual(store.savedVideoURLs, [videoURL])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(stub: MediaStoreSpy.Stub,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalMediaSaver, store: MediaStoreSpy) {
        let store = MediaStoreSpy(stub: stub)
        let sut = LocalMediaSaver(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func anyImageData() -> Data {
        UIImage.make(withColor: .gray).pngData()!
    }
    
    final private class MediaStoreSpy: MediaStore {
        typealias Stub = Result<Void, MediaStoreError>
        
        private(set) var savedImageData = [Data]()
        private(set) var savedVideoURLs = [URL]()
        
        private var stub: Stub
        
        init(stub: Stub) {
            self.stub = stub
        }

        func saveImageData(_ data: Data) async throws {
            savedImageData.append(data)
            try stub.get()
        }
        
        func saveVideo(for url: URL) async throws {
            savedVideoURLs.append(url)
            try stub.get()
        }
    }
}
