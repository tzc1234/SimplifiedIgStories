//
//  AVPhotoTakerTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 19/02/2024.
//

import XCTest
import AVKit
@testable import Simple_IG_Story

final class AVPhotoTakerTests: XCTestCase {
    func test_init_doesNotDeliverStatusUponInit() {
        let (sut, _) = makeSUT()
        let statusSpy = PhotoTakerStatusSpy(publisher: sut.getStatusPublisher())
        
        XCTAssertTrue(statusSpy.loggedStatuses.isEmpty)
    }
    
    func test_takePhoto_addsPhotoOutputToSessionIfNoPhotoOutputWhenSessionIsNotRunning() {
        let (sut, device) = makeSUT(isSessionRunning: false)
        
        XCTAssertEqual(device.loggedPhotoOutputs.count, 0)
        
        sut.takePhoto(on: .off)
        
        XCTAssertEqual(device.loggedPhotoOutputs.count, 1)
    }
    
    func test_takePhoto_addsPhotoOutputToSessionIfNoPhotoOutputWhenSessionIsRunning() {
        let (sut, device) = makeSUT(isSessionRunning: true)
        
        sut.takePhoto(on: .off)
        
        XCTAssertEqual(device.loggedPhotoOutputs.count, 1)
    }
    
    func test_takePhoto_doesNotAddPhotoOutputAgainWhenPhotoOutputIsAlreadyAdded() {
        let (sut, device) = makeSUT()
        
        sut.takePhoto(on: .off)
        sut.takePhoto(on: .off)
        
        XCTAssertEqual(device.loggedPhotoOutputs.count, 1)
    }
    
    func test_takePhoto_doesNotAddPhotoOutputAgainWhenPhotoOutputIsAlreadyExisted() {
        let existingPhotoOutput = AVCapturePhotoOutput()
        let (sut, device) = makeSUT(existingPhotoOutput: existingPhotoOutput)
        
        sut.takePhoto(on: .off)
        
        XCTAssertEqual(device.loggedPhotoOutputs, [existingPhotoOutput])
    }
    
    func test_takePhoto_deliversAddPhotoOutputFailureStatusWhenCannotAddPhotoOutput() {
        let (sut, device) = makeSUT(isSessionRunning: true, canAddOutput: false)
        let statusSpy = PhotoTakerStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.takePhoto(on: .off)
        
        XCTAssertTrue(device.loggedPhotoOutputs.isEmpty)
        XCTAssertEqual(statusSpy.loggedStatuses, [.addPhotoOutputFailure])
    }
    
    func test_takePhoto_triggersCapturePhotoSuccessfullyWhenSessionIsRunning() {
        let flashMode: CameraFlashMode = .off
        let (sut, device) = makeSUT(isSessionRunning: true)
        
        sut.takePhoto(on: flashMode)
        
        assertCapturePhotoOutput(device.photoOutput, with: sut, flashMode: flashMode)
    }
    
    func test_takePhoto_triggersCapturePhotoWithAutoFlashModeWhenSessionIsRunning() {
        let autoFlashMode: CameraFlashMode = .auto
        let (sut, device) = makeSUT(isSessionRunning: true)
        
        sut.takePhoto(on: autoFlashMode)
        
        assertCapturePhotoOutput(device.photoOutput, with: sut, flashMode: autoFlashMode)
    }
    
    func test_takePhoto_triggersCapturePhotoSuccessfullyWhenSessionIsRunningWithExistingPhotoOutput() {
        let photoOutput = CapturePhotoOutputSpy()
        let flashMode: CameraFlashMode = .on
        let (sut, _) = makeSUT(isSessionRunning: true, existingPhotoOutput: photoOutput)
        
        sut.takePhoto(on: flashMode)
        
        assertCapturePhotoOutput(photoOutput, with: sut, flashMode: flashMode)
    }
    
    func test_takePhoto_doesNotTriggerCapturePhotoWhenSessionIsNotRunning() {
        let (sut, device) = makeSUT(isSessionRunning: false)
        
        sut.takePhoto(on: .off)
        
        XCTAssertEqual(device.photoOutput?.capturePhotoCallCount, 0)
    }
    
    func test_takePhoto_performsOnSessionQueue() {
        var loggedActions = [() -> Void]()
        let (sut, device) = makeSUT(isSessionRunning: true, perform: { loggedActions.append($0) })
        
        sut.takePhoto(on: .off)
        
        XCTAssertTrue(device.loggedPhotoOutputs.isEmpty)
        XCTAssertNil(device.photoOutput)
        
        loggedActions.forEach { $0() }
        
        XCTAssertEqual(device.loggedPhotoOutputs.count, 1)
        XCTAssertEqual(device.photoOutput?.capturePhotoCallCount, 1)
    }
    
    func test_photoOutput_deliversImageConvertingFailureStatusWhenErrorOccurred() {
        let (sut, _) = makeSUT()
        let statusSpy = PhotoTakerStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.photoOutputWithError()
        
        XCTAssertEqual(statusSpy.loggedStatuses, [.imageConvertingFailure])
    }
    
    func test_photoOutput_deliversImageConvertingFailureStatusWhenNoPhotoData() {
        let (sut, _) = makeSUT()
        let statusSpy = PhotoTakerStatusSpy(publisher: sut.getStatusPublisher())
        
        sut.photoOutput(fileData: nil)
        
        XCTAssertEqual(statusSpy.loggedStatuses, [.imageConvertingFailure])
    }
    
    func test_photoOutput_deliversPhotoSuccessfullyWhenHavingFileData() {
        let (sut, _) = makeSUT()
        let statusSpy = PhotoTakerStatusSpy(publisher: sut.getStatusPublisher())
        let fileData = UIImage.makeData(withColor: .red)
        
        sut.photoOutput(fileData: fileData)
        
        XCTAssertEqual(statusSpy.loggedStatuses.count, 1)
        XCTAssertNotNil(statusSpy.photoTakenData)
    }
    
    // MARK: - Helpers
    
    private typealias PhotoTakerStatusSpy = StatusSpy<PhotoTakerStatus>
    
    private func makeSUT(isSessionRunning: Bool = false,
                         canAddOutput: Bool = true,
                         existingPhotoOutput: AVCapturePhotoOutput? = nil,
                         perform: @escaping (@escaping () -> Void) -> Void = { $0() },
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: AVPhotoTaker, device: PhotoCaptureDeviceSpy) {
        CaptureSessionSpy.swizzled()
        let device = PhotoCaptureDeviceSpy(
            isSessionRunning: isSessionRunning,
            canAddOutput: canAddOutput,
            existingPhotoOutput: existingPhotoOutput,
            performOnSessionQueue: perform
        )
        let sut = AVPhotoTaker(device: device, makeCapturePhotoOutput: CapturePhotoOutputSpy.init)
        addTeardownBlock { CaptureSessionSpy.revertSwizzled() }
        trackForMemoryLeaks(device, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, device)
    }
    
    private func assertCapturePhotoOutput(_ output: CapturePhotoOutputSpy?,
                                          with sut: AVPhotoTaker,
                                          flashMode: CameraFlashMode,
                                          file: StaticString = #filePath,
                                          line: UInt = #line) {
        XCTAssertEqual(output?.capturePhotoCallCount, 1, file: file, line: line)
        XCTAssertIdentical(output?.loggedDelegates.last, sut, file: file, line: line)
        let setting = output?.loggedSettings.last
        XCTAssertEqual(setting?.flashMode, flashMode.toCaptureDeviceFlashMode(), file: file, line: line)
    }
    
    private final class PhotoCaptureDeviceSpy: CaptureDevice {
        let session: AVCaptureSession
        var loggedPhotoOutputs: [AVCapturePhotoOutput] {
            (session as! CaptureSessionSpy).loggedPhotoOutputs
        }
        var photoOutput: CapturePhotoOutputSpy? {
            loggedPhotoOutputs.last as? CapturePhotoOutputSpy
        }
        
        private(set) var cameraPosition: CameraPosition = .back
        
        let performOnSessionQueue: (@escaping () -> Void) -> Void
        
        init(isSessionRunning: Bool,
             canAddOutput: Bool,
             existingPhotoOutput: AVCapturePhotoOutput? = nil,
             performOnSessionQueue: @escaping (@escaping () -> Void) -> Void) {
            let session = CaptureSessionSpy(isRunning: isSessionRunning, canAddOutput: canAddOutput)
            existingPhotoOutput.map { session.loggedOutputs.append($0) }
            
            self.session = session
            self.performOnSessionQueue = performOnSessionQueue
        }
    }
}

private extension AVPhotoTaker {
    func photoOutput(fileData: Data?) {
        let photo = makeCapturePhoto(fileData: fileData)
        photoOutput(AVCapturePhotoOutput(), didFinishProcessingPhoto: photo, error: nil)
    }
    
    func photoOutputWithError() {
        photoOutput(AVCapturePhotoOutput(), didFinishProcessingPhoto: makeCapturePhoto(), error: anyNSError())
    }
    
    private func makeCapturePhoto(fileData: Data? = nil) -> CapturePhotoStub {
        let klass = CapturePhotoStub.self as NSObject.Type
        let photo = klass.init() as! CapturePhotoStub
        photo.fileData = fileData
        return photo
    }
}

private extension StatusSpy<PhotoTakerStatus> {
    var photoTakenData: Data? {
        if case let .photoTaken(photo: photo) = loggedStatuses.last {
            return photo.pngData()
        }
        
        return nil
    }
}
