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
        
        clearImageFileArtefacts()
    }
    
    override func tearDown() {
        super.tearDown()
        
        clearImageFileArtefacts()
    }
    
    func test_getImage_doesNotDeliverImageWhenNoImage() {
        let sut = makeSUT()
        
        let image = sut.getImage(for: imageFileURL())
        
        XCTAssertNil(image)
    }
    
    func test_getImageTwice_ensuresNoSideEffectsWhenNoImage() {
        let sut = makeSUT()
        let url = imageFileURL()
        
        let firstReceivedImage = sut.getImage(for: url)
        let lastReceivedImage = sut.getImage(for: url)
        
        XCTAssertNil(firstReceivedImage)
        XCTAssertNil(lastReceivedImage)
    }
    
    func test_saveImage_deliversSaveFailedErrorOnSaveError() {
        let sut = makeSUT()
        let image = UIImage.make(withColor: .red)
        let invalidFileName = "invalid://fileName"
        
        XCTAssertThrowsError(try sut.saveImage(image, fileName: invalidFileName)) { error in
            XCTAssertEqual(error as? ImageFileManageableError, .saveFailed)
        }
    }
    
    func test_saveImage_deliversJpegConversionFailedErrorOnConversionError() {
        let sut = makeSUT()
        let image = UIImage()
        
        XCTAssertThrowsError(try sut.saveImage(image, fileName: imageFileName())) { error in
            XCTAssertEqual(error as? ImageFileManageableError, .jpegConversionFailed)
        }
    }
    
    func test_saveImage_deliversImageURLWhenSaveSuccessfully() throws {
        let sut = makeSUT()
        let image = UIImage.make(withColor: .red)
        let expectedFileURL = imageFileURL()
        
        let receivedURL = try sut.saveImage(image, fileName: imageFileName())
        
        XCTAssertEqual(receivedURL, expectedFileURL)
    }
    
    func test_getImage_deliversSavedImageWhenSavedImageExisted() throws {
        let sut = makeSUT()
        let image = UIImage.make(withColor: .red)
        
        let receivedURL = try sut.saveImage(image, fileName: imageFileName())
        let receivedImage = sut.getImage(for: receivedURL)
        
        XCTAssertNotNil(receivedImage)
    }
    
    func test_getImageTwice_ensuresNoSideEffectsWhenSavedImageExisted() throws {
        let sut = makeSUT()
        let image = UIImage.make(withColor: .red)
        
        let receivedURL = try sut.saveImage(image, fileName: imageFileName())
        let firstReceivedImage = sut.getImage(for: receivedURL)
        let lastReceivedImage = sut.getImage(for: receivedURL)
        
        XCTAssertNotNil(firstReceivedImage)
        XCTAssertEqual(firstReceivedImage?.pngData(), lastReceivedImage?.pngData())
    }
    
    func test_deleteImage_deliversFileForDeletionNotFoundErrorWhenImageFileNotExisted() {
        let sut = makeSUT()
        
        XCTAssertThrowsError(try sut.deleteImage(for: imageFileURL())) { error in
            XCTAssertEqual(error as? ImageFileManageableError, .fileForDeletionNotFound)
        }
    }
    
    func test_deleteImage_deliversDeleteFailedErrorOnDeletionError() {
        FileManager.swizzled()
        let sut = makeSUT()
        let image = UIImage.make(withColor: .red)
        
        _ = try! sut.saveImage(image, fileName: imageFileName())
        
        XCTAssertThrowsError(try sut.deleteImage(for: imageFileURL())) { error in
            XCTAssertEqual(error as? ImageFileManageableError, .deleteFailed)
        }
        FileManager.revertSwizzled()
    }
    
    func test_deleteImage_deletesImageSuccessfullyWhenSavedImageExisted() throws {
        let sut = makeSUT()
        let image = UIImage.make(withColor: .red)
        
        let receivedURL = try sut.saveImage(image, fileName: imageFileName())
        try sut.deleteImage(for: receivedURL)
        let receivedImage = sut.getImage(for: receivedURL)
        
        XCTAssertNil(receivedImage)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> LocalImageFileManager {
        let sut = LocalImageFileManager(directory: directory(), fileExtension: imageFileExtension())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func imageFileURL() -> URL {
        directory().appendingPathComponent("\(imageFileName())").appendingPathExtension(imageFileExtension())
    }
    
    private func directory() -> URL {
        FileManager.default.temporaryDirectory
    }
    
    private func imageFileName() -> String {
        "img_test"
    }
    
    private func imageFileExtension() -> String {
        "jpg"
    }
    
    private func clearImageFileArtefacts() {
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