//
//  LocalMediaSaverTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 09/02/2024.
//

import XCTest

final class LocalMediaSaver {
    private let store: MediaStore
    
    init(store: MediaStore) {
        self.store = store
    }
    
    enum Error: Swift.Error {
        case noPermission
        case failed
    }
    
    func saveImage(_ image: UIImage) async throws {
        do {
            try await store.saveImage(image)
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

protocol MediaStore {
    func saveImage(_ image: UIImage) async throws
    func saveVideo(by: URL) async throws
}

enum MediaStoreError: Error {
    case noPermission
    case failed
}

final class MediaStoreStub: MediaStore {
    typealias Stub = Result<Void, MediaStoreError>
    
    private(set) var savedImages = [UIImage]()
    private(set) var savedVideoURLs = [URL]()
    
    private var stubs: [Stub]
    
    init(stubs: [Stub]) {
        self.stubs = stubs
    }

    func saveImage(_ image: UIImage) async throws {
        savedImages.append(image)
        try stubs.removeLast().get()
    }
    
    func saveVideo(by url: URL) async throws {
        savedVideoURLs.append(url)
        try stubs.removeLast().get()
    }
}

final class LocalMediaSaverTests: XCTestCase {
    func test_saveImage_deliversNoPermissionErrorOnStoreNoPermissionError() async {
        let (sut, _) = makeSUT(stubs: [.failure(.noPermission)])
        
        await assertThrowsError(try await sut.saveImage(anyImage())) { error in
            XCTAssertEqual(error as? LocalMediaSaver.Error, .noPermission)
        }
    }
    
    func test_saveImage_deliversFailedErrorWhenStoreFailedOnSave() async {
        let (sut, _) = makeSUT(stubs: [.failure(.failed)])
        
        await assertThrowsError(try await sut.saveImage(anyImage())) { error in
            XCTAssertEqual(error as? LocalMediaSaver.Error, .failed)
        }
    }
    
    func test_saveImage_saveSuccessfullyIntoStore() async throws {
        let (sut, store) = makeSUT(stubs: [.success(())])
        let image = UIImage.make(withColor: .red)
        
        try await sut.saveImage(image)
        
        XCTAssertEqual(store.savedImages, [image])
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
    
    private func makeSUT(stubs: [MediaStoreStub.Stub],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalMediaSaver, store: MediaStoreStub) {
        let store = MediaStoreStub(stubs: stubs)
        let sut = LocalMediaSaver(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func anyImage() -> UIImage {
        .make(withColor: .gray)
    }
    
    private func anyVideoURL() -> URL {
        URL(string: "file://any-video.mp4")!
    }
}
