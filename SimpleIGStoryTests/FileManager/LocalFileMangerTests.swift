//
//  LocalFileMangerTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 12/03/2024.
//

import XCTest
@testable import Simple_IG_Story

final class LocalFileMangerTests: XCTestCase {
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
