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
    
    func test_deletePortionMedia_deletesMediaWhenVideoTypePortionResourceURLIsExisted() {
        let fileManager = FileManagerSpy()
        let videoURL = anyVideoURL()
        let sut = makeSUT(portion: makePortion(resourceURL: videoURL, type: .video), fileManager: fileManager)
        
        sut.deletePortionMedia()
        
        XCTAssertEqual(fileManager.loggedURLsForDeletion, [videoURL])
    }
    
    func test_saveMedia_doesNotSaveImageWhenNoImageData() async {
        let fileManager = FileManagerSpy(getImageStub: { _ in nil })
        let mediaSaver = MediaSaverSpy()
        let imageURL = anyImageURL()
        let sut = makeSUT(
            portion: makePortion(resourceURL: imageURL, type: .image),
            fileManager: fileManager,
            mediaSaver: mediaSaver
        )
        
        await sut.saveMedia()
        
        XCTAssertEqual(mediaSaver.saveImageDataCallCount, 0)
    }
    
    func test_saveMedia_savesImageSuccessfully() async {
        let fileManager = FileManagerSpy(getImageStub: { url in UIImage.make(withColor: .red) })
        let mediaSaver = MediaSaverSpy()
        let imageURL = anyImageURL()
        let sut = makeSUT(
            portion: makePortion(resourceURL: imageURL, type: .image),
            fileManager: fileManager,
            mediaSaver: mediaSaver
        )
        
        await sut.saveMedia()
        
        XCTAssertEqual(mediaSaver.saveImageDataCallCount, 1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(portion: Portion, 
                         fileManager: FileManageable = FileManagerSpy(getImageStub: { _ in nil }),
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
    private let getImageStub: (URL) -> UIImage?
    
    init(getImageStub: @escaping (URL) -> UIImage? = { _ in nil }) {
        self.getImageStub = getImageStub
    }
    
    func saveImage(_ image: UIImage, fileName: String) throws -> URL {
        anyImageURL()
    }
    
    func getImage(for url: URL) -> UIImage? {
        getImageStub(url)
    }
    
    func delete(for url: URL) throws {
        loggedURLsForDeletion.append(url)
    }
}

final class MediaSaverSpy: MediaSaver {
    private(set) var saveImageDataCallCount = 0
    
    func saveImageData(_ data: Data) async throws {
        saveImageDataCallCount += 1
    }
    
    func saveVideo(by url: URL) async throws {
        
    }
}
