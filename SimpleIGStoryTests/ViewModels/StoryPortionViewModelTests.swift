//
//  StoryPortionViewModelTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 23/03/2024.
//

import XCTest
@testable import Simple_IG_Story

final class StoryPortionViewModelTests: XCTestCase {
    func test_deletePortionMedia_ignoresWhenNoPortionResourceURL() {
        let fileManager = FileManagerSpy()
        let sut = makeSUT(portion: makePortion(resourceURL: nil), fileManager: fileManager)
        
        sut.deletePortionMedia()
        
        XCTAssertTrue(fileManager.loggedURLsForDeletion.isEmpty)
    }
    
    func test_deletePortionMedia_deletesMediaWhenImageTypePortionResourceURLIsExisted() {
        let fileManager = FileManagerSpy()
        let imageURL = anyImageURL()
        let sut = makeSUT(portion: makePortion(resourceURL: imageURL, type: .image), fileManager: fileManager)
        
        sut.deletePortionMedia()
        
        XCTAssertEqual(fileManager.loggedURLsForDeletion, [imageURL])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(portion: Portion, 
                         fileManager: FileManageable = FileManagerSpy(),
                         mediaSaver: MediaSaver = MediaSaverSpy()) -> StoryPortionViewModel {
        let sut = StoryPortionViewModel(
            story: makeStory(),
            portion: portion,
            fileManager: fileManager,
            mediaSaver: mediaSaver
        )
        return sut
    }
}

final class FileManagerSpy: FileManageable {
    private(set) var loggedURLsForDeletion = [URL]()
    
    func saveImage(_ image: UIImage, fileName: String) throws -> URL {
        anyImageURL()
    }
    
    func getImage(for url: URL) -> UIImage? {
        nil
    }
    
    func delete(for url: URL) throws {
        loggedURLsForDeletion.append(url)
    }
}

final class MediaSaverSpy: MediaSaver {
    func saveImageData(_ data: Data) async throws {
        
    }
    
    func saveVideo(by url: URL) async throws {
        
    }
}
