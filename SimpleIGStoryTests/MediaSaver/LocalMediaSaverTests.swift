//
//  LocalMediaSaverTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 09/02/2024.
//

import XCTest
@testable import Simple_IG_Story

final class LocalMediaSaver {
    private let store: MediaStore
    
    init(store: MediaStore) {
        self.store = store
    }
    
    enum Error: Swift.Error {
        case noPermission
        case failed
    }
    
    func saveImageData(_ data: Data) async throws {
        do {
            try await store.saveImageData(data)
        } catch MediaStoreError.noPermission {
            throw Error.noPermission
        } catch {
            throw Error.failed
        }
    }
    
    func saveVideo(by url: URL) async throws {
        do {
            try await store.saveVideo(by: url)
        } catch MediaStoreError.noPermission {
            throw Error.noPermission
        } catch {
            throw Error.failed
        }
    }
}

final class MediaStoreSpy: MediaStore {
    typealias Stub = Result<Void, MediaStoreError>
    
    private(set) var savedImageData = [Data]()
    private(set) var savedVideoURLs = [URL]()
    
    private var stubs: [Stub]
    
    init(stubs: [Stub]) {
        self.stubs = stubs
    }

    func saveImageData(_ data: Data) async throws {
        savedImageData.append(data)
        try stubs.removeLast().get()
    }
    
    func saveVideo(by url: URL) async throws {
        savedVideoURLs.append(url)
        try stubs.removeLast().get()
    }
}

final class LocalMediaSaverTests: XCTestCase {
    func test_saveImageData_deliversNoPermissionErrorOnStoreNoPermissionError() async {
        let (sut, _) = makeSUT(stubs: [.failure(.noPermission)])
        
        await assertThrowsError(try await sut.saveImageData(anyImageData())) { error in
            XCTAssertEqual(error as? LocalMediaSaver.Error, .noPermission)
        }
    }
    
    func test_saveImageData_deliversFailedErrorWhenStoreFailedOnSave() async {
        let (sut, _) = makeSUT(stubs: [.failure(.failed)])
        
        await assertThrowsError(try await sut.saveImageData(anyImageData())) { error in
            XCTAssertEqual(error as? LocalMediaSaver.Error, .failed)
        }
    }
    
    func test_saveImageData_saveSuccessfullyIntoStore() async throws {
        let (sut, store) = makeSUT(stubs: [.success(())])
        let imageData = UIImage.make(withColor: .red).pngData()!
        
        try await sut.saveImageData(imageData)
        
        XCTAssertEqual(store.savedImageData, [imageData])
    }
    
    func test_saveVideo_deliversNoPermissionErrorOnStoreNoPermissionError() async {
        let (sut, _) = makeSUT(stubs: [.failure(.noPermission)])
        
        await assertThrowsError(try await sut.saveVideo(by: anyVideoURL())) { error in
            XCTAssertEqual(error as? LocalMediaSaver.Error, .noPermission)
        }
    }
    
    func test_saveVideo_deliversFailedErrorWhenStoreFailedOnSave() async {
        let (sut, _) = makeSUT(stubs: [.failure(.failed)])
        
        await assertThrowsError(try await sut.saveVideo(by: anyVideoURL())) { error in
            XCTAssertEqual(error as? LocalMediaSaver.Error, .failed)
        }
    }
    
    func test_saveVideo_saveSuccessfullyIntoStore() async throws {
        let (sut, store) = makeSUT(stubs: [.success(())])
        let videoURL = URL(string: "file://video.mp4")!
        
        try await sut.saveVideo(by: videoURL)
        
        XCTAssertEqual(store.savedVideoURLs, [videoURL])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(stubs: [MediaStoreSpy.Stub],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalMediaSaver, store: MediaStoreSpy) {
        let store = MediaStoreSpy(stubs: stubs)
        let sut = LocalMediaSaver(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func anyImageData() -> Data {
        UIImage.make(withColor: .gray).pngData()!
    }
    
    private func anyVideoURL() -> URL {
        URL(string: "file://any-video.mp4")!
    }
}
