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
    }
    
    func saveImage(_ image: UIImage) async throws {
        throw Error.noPermission
    }
}

protocol MediaStore {
    func saveImage(_ image: UIImage) async throws
}

enum MediaStoreError: Error {
    case noPermission
}

final class MediaStoreStub: MediaStore {
    typealias Stub = Result<Void, MediaStoreError>
    
    private var stubs: [Stub]
    
    init(stubs: [Stub]) {
        self.stubs = stubs
    }

    func saveImage(_ image: UIImage) async throws {
        try stubs.removeLast().get()
    }
}

final class LocalMediaSaverTests: XCTestCase {
    func test_saveImage_deliversNoPermissionErrorOnStoreNoPermissionError() async {
        let store = MediaStoreStub(stubs: [.failure(.noPermission)])
        let sut = LocalMediaSaver(store: store)
        let anyImage = UIImage.make(withColor: .red)
        
        await assertThrowsError(try await sut.saveImage(anyImage)) { error in
            XCTAssertEqual(error as? LocalMediaSaver.Error, .noPermission)
        }
    }
}
