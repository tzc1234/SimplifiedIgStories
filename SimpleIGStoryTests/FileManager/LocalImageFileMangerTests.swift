//
//  LocalImageFileMangerTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 12/03/2024.
//

import XCTest
@testable import Simple_IG_Story

final class LocalImageFileMangerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        clearFileArtefacts()
    }
    
    override func tearDown() {
        super.tearDown()
        
        clearFileArtefacts()
    }
    
    func test_getImage_doesNotDeliverImageWhenNoImage() {
        let sut = LocalImageFileManager()
        
        let image = sut.getImage(for: imageFileURL())
        
        XCTAssertNil(image)
    }
    
    func test_getImageTwice_ensuresNoSideEffectsWhenNoImage() {
        let sut = LocalImageFileManager()
        let url = imageFileURL()
        
        let firstReceivedImage = sut.getImage(for: url)
        let lastReceivedImage = sut.getImage(for: url)
        
        XCTAssertNil(firstReceivedImage)
        XCTAssertNil(lastReceivedImage)
    }
    
    func test_saveImage_deliversSaveFailedErrorOnSaveError() {
        let sut = LocalImageFileManager()
        let image = UIImage.make(withColor: .red)
        let invalidFileName = "invalid://fileName"
        
        XCTAssertThrowsError(try sut.saveImage(image, fileName: invalidFileName)) { error in
            XCTAssertEqual(error as? ImageFileManageableError, .saveFailed)
        }
    }
    
    func test_saveImage_deliversJpegConversionFailedErrorOnConversionError() {
        let sut = LocalImageFileManager()
        let image = UIImage()
        
        XCTAssertThrowsError(try sut.saveImage(image, fileName: imageFileName())) { error in
            XCTAssertEqual(error as? ImageFileManageableError, .jpegConversionFailed)
        }
    }
    
    func test_saveImage_deliversImageURLWhenSaveSuccessfully() throws {
        let sut = LocalImageFileManager()
        let image = UIImage.make(withColor: .red)
        let expectedFileURL = imageFileURL()
        
        let receivedURL = try sut.saveImage(image, fileName: imageFileName())
        
        XCTAssertEqual(receivedURL, expectedFileURL)
    }
    
    func test_getImage_deliversSavedImageWhenSavedImageExisted() throws {
        let sut = LocalImageFileManager()
        let image = UIImage.make(withColor: .red)
        
        let receivedURL = try sut.saveImage(image, fileName: imageFileName())
        let receivedImage = sut.getImage(for: receivedURL)
        
        XCTAssertNotNil(receivedImage)
    }
    
    func test_getImageTwice_ensuresNoSideEffectsWhenSavedImageExisted() throws {
        let sut = LocalImageFileManager()
        let image = UIImage.make(withColor: .red)
        
        let receivedURL = try sut.saveImage(image, fileName: imageFileName())
        let firstReceivedImage = sut.getImage(for: receivedURL)
        let lastReceivedImage = sut.getImage(for: receivedURL)
        
        XCTAssertNotNil(firstReceivedImage)
        XCTAssertEqual(firstReceivedImage?.pngData(), lastReceivedImage?.pngData())
    }
    
    func test_deleteImage_deliversFileForDeletionNotFoundErrorWhenImageFileNotExisted() {
        let sut = LocalImageFileManager()
        
        XCTAssertThrowsError(try sut.deleteImage(for: imageFileURL())) { error in
            XCTAssertEqual(error as? ImageFileManageableError, .fileForDeletionNotFound)
        }
    }
    
    func test_deleteImage_deliversDeleteFailedErrorOnDeletionError() {
        FileManager.swizzled()
        let sut = LocalImageFileManager()
        let image = UIImage.make(withColor: .red)
        
        _ = try! sut.saveImage(image, fileName: imageFileName())
        
        XCTAssertThrowsError(try sut.deleteImage(for: imageFileURL())) { error in
            XCTAssertEqual(error as? ImageFileManageableError, .deleteFailed)
        }
        FileManager.revertSwizzled()
    }
    
    func test_deleteImage_deletesImageSuccessfullyWhenSavedImageExisted() throws {
        let sut = LocalImageFileManager()
        let image = UIImage.make(withColor: .red)
        
        let receivedURL = try sut.saveImage(image, fileName: imageFileName())
        try sut.deleteImage(for: receivedURL)
        let receivedImage = sut.getImage(for: receivedURL)
        
        XCTAssertNil(receivedImage)
    }
    
    // MARK: - Helpers
    
    private func imageFileName() -> String {
        "test"
    }
    
    private func imageFileURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(imageFileName()).jpg")
    }
    
    private func clearFileArtefacts() {
        try? FileManager.default.removeItem(at: imageFileURL())
    }
}

extension FileManager: MethodSwizzling {
    @objc func alwaysFailRemoveItem(at URL: URL) throws {
        throw anyNSError()
    }
    
    static var instanceMethodPairs: [MethodPair] {
        [
            .init(
                from: (class: FileManager.self, method: #selector(FileManager.removeItem(at:))),
                to: (class: FileManager.self, method: #selector(FileManager.alwaysFailRemoveItem(at:)))
            )
        ]
    }
}
