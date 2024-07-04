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
    
    func test_saveImageMedia_doesNotSaveImageWhenNoImageData() async {
        let fileManager = FileManagerSpy(getImageStub: { _ in nil })
        let mediaSaver = MediaSaverSpy()
        let sut = makeSUT(
            portion: makePortion(resourceURL: anyImageURL(), type: .image),
            fileManager: fileManager,
            mediaSaver: mediaSaver
        )
        
        await sut.saveMedia()
        
        XCTAssertEqual(mediaSaver.saveImageDataCallCount, 0)
    }
    
    func test_saveImageMedia_showsNoPermissionMessageOnNoPermissionError() async {
        let fileManager = FileManagerSpy(getImageStub: { _ in anyUIImage() })
        let mediaSaver = MediaSaverSpy(saveImageDataStub: { throw MediaSaverError.noPermission })
        let sut = makeSUT(
            portion: makePortion(resourceURL: anyImageURL(), type: .image),
            fileManager: fileManager,
            mediaSaver: mediaSaver,
            skipPerformNoticeMessageReset: true
        )
        
        await sut.saveMedia()
        
        XCTAssertEqual(sut.noticeMessage, "Couldn't save. No add photo permission.")
    }
    
    func test_saveImageMedia_showsSavedFailedMessageOnAnyError() async {
        let fileManager = FileManagerSpy(getImageStub: { _ in anyUIImage() })
        let mediaSaver = MediaSaverSpy(saveImageDataStub: { throw anyNSError() })
        let sut = makeSUT(
            portion: makePortion(resourceURL: anyImageURL(), type: .image),
            fileManager: fileManager,
            mediaSaver: mediaSaver,
            skipPerformNoticeMessageReset: true
        )
        
        await sut.saveMedia()
        
        XCTAssertEqual(sut.noticeMessage, "Save failed.")
    }
    
    func test_saveImageMedia_savesImageSuccessfully() async {
        let fileManager = FileManagerSpy(getImageStub: { _ in anyUIImage() })
        let mediaSaver = MediaSaverSpy()
        let sut = makeSUT(
            portion: makePortion(resourceURL: anyImageURL(), type: .image),
            fileManager: fileManager,
            mediaSaver: mediaSaver,
            skipPerformNoticeMessageReset: true
        )
        
        await sut.saveMedia()
        
        XCTAssertEqual(mediaSaver.saveImageDataCallCount, 1)
        XCTAssertEqual(sut.noticeMessage, "Saved.")
    }
    
    func test_saveVideoMedia_showsNoPermissionMessageOnNoPermissionError() async {
        let fileManager = FileManagerSpy(getImageStub: { _ in anyUIImage() })
        let mediaSaver = MediaSaverSpy(saveVideoStub: { throw MediaSaverError.noPermission })
        let sut = makeSUT(
            portion: makePortion(resourceURL: anyVideoURL(), type: .video),
            fileManager: fileManager,
            mediaSaver: mediaSaver,
            skipPerformNoticeMessageReset: true
        )
        
        await sut.saveMedia()
        
        XCTAssertEqual(sut.noticeMessage, "Couldn't save. No add photo permission.")
    }
    
    func test_saveVideoMedia_showsSavedFailedMessageOnAnyError() async {
        let fileManager = FileManagerSpy(getImageStub: { _ in anyUIImage() })
        let mediaSaver = MediaSaverSpy(saveVideoStub: { throw anyNSError() })
        let sut = makeSUT(
            portion: makePortion(resourceURL: anyVideoURL(), type: .video),
            fileManager: fileManager,
            mediaSaver: mediaSaver,
            skipPerformNoticeMessageReset: true
        )
        
        await sut.saveMedia()
        
        XCTAssertEqual(sut.noticeMessage, "Save failed.")
    }
    
    func test_saveVideoMedia_savesVideoSuccessfully() async {
        let fileManager = FileManagerSpy(getImageStub: { _ in anyUIImage() })
        let mediaSaver = MediaSaverSpy()
        let sut = makeSUT(
            portion: makePortion(resourceURL: anyVideoURL(), type: .video),
            fileManager: fileManager,
            mediaSaver: mediaSaver,
            skipPerformNoticeMessageReset: true
        )
        
        await sut.saveMedia()
        
        XCTAssertEqual(mediaSaver.saveVideoCallCount, 1)
        XCTAssertEqual(sut.noticeMessage, "Saved.")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(portion: Portion, 
                         fileManager: FileManageable = FileManagerSpy(getImageStub: { _ in nil }),
                         mediaSaver: MediaSaver = MediaSaverSpy(),
                         skipPerformNoticeMessageReset: Bool = false) -> StoryPortionViewModel {
        let sut = StoryPortionViewModel(
            story: makeStory(),
            portion: portion,
            fileManager: fileManager,
            mediaSaver: mediaSaver,
            performAfterPointOneSecond: { $0() },
            performAfterOnePointFiveSecond: skipPerformNoticeMessageReset ? { _ in } : { $0() }
        )
        return sut
    }
    
    private final class FileManagerSpy: FileManageable {
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
}
