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
        let statusSpy = StatusSpy<PhotoTakerStatus>(publisher: sut.getStatusPublisher())
        
        XCTAssertTrue(statusSpy.loggedStatuses.isEmpty)
    }
    
    func test_takePhoto_addsPhotoOutputToSessionIfNoPhotoOutputWhenSessionIsRunning() {
        let (sut, device) = makeSUT(isSessionRunning: true)
        
        sut.takePhoto(on: .off)
        
        XCTAssertEqual(device.loggedPhotoOutputs.count, 1)
    }
    
    func test_takePhoto_doesNotAddPhotoOutputAgainWhenPhotoOutputIsAlreadyAddedAndSessionIsRunning() {
        let (sut, device) = makeSUT(isSessionRunning: true)
        
        sut.takePhoto(on: .off)
        sut.takePhoto(on: .off)
        
        XCTAssertEqual(device.loggedPhotoOutputs.count, 1)
    }
    
    func test_takePhoto_deliversAddPhotoOutputFailureStatusWhenCannotAddPhotoOutput() {
        let (sut, device) = makeSUT(isSessionRunning: true, canAddOutput: false)
        let statusSpy = StatusSpy<PhotoTakerStatus>(publisher: sut.getStatusPublisher())
        
        sut.takePhoto(on: .off)
        
        XCTAssertTrue(device.loggedPhotoOutputs.isEmpty)
        XCTAssertEqual(statusSpy.loggedStatuses, [.addPhotoOutputFailure])
    }
    
    func test_takePhoto_triggersCapturePhotoSuccessfullyWhenSessionIsRunning() throws {
        let photoOutputSpy = CapturePhotoOutputSpy()
        let flashMode: CameraFlashMode = .off
        let (sut, _) = makeSUT(isSessionRunning: true, capturePhotoOutput: { photoOutputSpy })
        
        sut.takePhoto(on: flashMode)
        
        assertCapturePhotoParams(in: photoOutputSpy, with: sut, andExpected: flashMode)
    }
    
    func test_takePhoto_doesNotTriggerCapturePhotoWhenSessionIsNotRunning() throws {
        let photoOutputSpy = CapturePhotoOutputSpy()
        let (sut, _) = makeSUT(isSessionRunning: false, capturePhotoOutput: { photoOutputSpy })
        
        sut.takePhoto(on: .off)
        
        XCTAssertEqual(photoOutputSpy.capturePhotoCallCount, 0)
    }
    
    func test_takePhoto_performsInSessionQueue() {
        let photoOutputSpy = CapturePhotoOutputSpy()
        var actions = [() -> Void]()
        let (sut, device) = makeSUT(
            isSessionRunning: true,
            capturePhotoOutput: { photoOutputSpy },
            perform: { actions.append($0) }
        )
        
        sut.takePhoto(on: .off)
        
        XCTAssertTrue(device.loggedPhotoOutputs.isEmpty)
        XCTAssertEqual(photoOutputSpy.capturePhotoCallCount, 0)
        
        let exp = expectation(description: "Wait for session queue")
        actions.forEach { action in
            action()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        
        XCTAssertEqual(device.loggedPhotoOutputs.count, 1)
        XCTAssertEqual(photoOutputSpy.capturePhotoCallCount, 1)
    }
    
    func test_photoOutput_deliversImageConvertingFailureStatusWhenErrorOccurred() {
        let (sut, _) = makeSUT()
        let statusSpy = StatusSpy<PhotoTakerStatus>(publisher: sut.getStatusPublisher())
        let anyPhotoOutput = CapturePhotoOutputSpy()
        let anyPhoto = makeCapturePhoto()
        
        sut.photoOutput(anyPhotoOutput, didFinishProcessingPhoto: anyPhoto, error: anyNSError())
        
        XCTAssertEqual(statusSpy.loggedStatuses, [.imageConvertingFailure])
    }
    
    func test_photoOutput_deliversImageConvertingFailureStatusWhenNoPhotoData() {
        let (sut, _) = makeSUT()
        let statusSpy = StatusSpy<PhotoTakerStatus>(publisher: sut.getStatusPublisher())
        let anyPhotoOutput = CapturePhotoOutputSpy()
        let noFileDataPhoto = makeCapturePhoto(fileData: nil)
        
        sut.photoOutput(anyPhotoOutput, didFinishProcessingPhoto: noFileDataPhoto, error: nil)
        
        XCTAssertEqual(statusSpy.loggedStatuses, [.imageConvertingFailure])
    }
    
    func test_photoOutput_deliversPhotoSuccessfullyWhenHavingFileData() {
        let (sut, _) = makeSUT()
        let statusSpy = StatusSpy<PhotoTakerStatus>(publisher: sut.getStatusPublisher())
        let anyPhotoOutput = CapturePhotoOutputSpy()
        let photo = makeCapturePhoto(fileData: UIImage.makeData(withColor: .red))
        
        sut.photoOutput(anyPhotoOutput, didFinishProcessingPhoto: photo, error: nil)
        
        XCTAssertEqual(statusSpy.loggedStatuses.count, 1)
        if case let .photoTaken(photo: receivedPhoto) = statusSpy.loggedStatuses.last {
            XCTAssertFalse(receivedPhoto.pngData()!.isEmpty)
        } else {
            XCTFail("Should receive a photo")
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(isSessionRunning: Bool = false,
                         canAddOutput: Bool = true,
                         capturePhotoOutput: @escaping () -> AVCapturePhotoOutput = CapturePhotoOutputSpy.init,
                         perform: @escaping (@escaping () -> Void) -> Void = { $0() },
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: AVPhotoTaker, device: PhotoCaptureDeviceSpy) {
        let device = PhotoCaptureDeviceSpy(
            isSessionRunning: isSessionRunning,
            canAddOutput: canAddOutput,
            performOnSessionQueue: perform
        )
        let sut = AVPhotoTaker(device: device, makeCapturePhotoOutput: capturePhotoOutput)
        trackForMemoryLeaks(device, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, device)
    }
    
    private func assertCapturePhotoParams(in output: CapturePhotoOutputSpy,
                                          with sut: AVPhotoTaker,
                                          andExpected flashMode: CameraFlashMode,
                                          file: StaticString = #filePath,
                                          line: UInt = #line) {
        XCTAssertEqual(output.capturePhotoCallCount, 1, file: file, line: line)
        XCTAssertIdentical(output.loggedDelegates.last, sut, file: file, line: line)
        let setting = output.loggedSettings.last
        XCTAssertEqual(setting?.flashMode, flashMode.toCaptureDeviceFlashMode(), file: file, line: line)
    }
    
    private func makeCapturePhoto(fileData: Data? = nil) -> AVCapturePhotoStub {
        AVCapturePhoto.swizzled()
        let photo = AVCapturePhotoStub(mock: "")
        AVCapturePhoto.revertSwizzled()
        
        photo.fileData = fileData
        return photo
    }
    
    private final class PhotoCaptureDeviceSpy: PhotoCaptureDevice {
        let session: AVCaptureSession
        var loggedPhotoOutputs: [AVCapturePhotoOutput] {
            (session as! CaptureSessionSpy).loggedPhotoOutputs
        }
        var shouldAddPhotoOutput: Bool {
            loggedPhotoOutputs.isEmpty
        }
        
        private(set) var cameraPosition: CameraPosition = .back
        
        let performOnSessionQueue: (@escaping () -> Void) -> Void
        
        init(isSessionRunning: Bool,
             canAddOutput: Bool,
             performOnSessionQueue: @escaping (@escaping () -> Void) -> Void) {
            self.session = CaptureSessionSpy(isRunning: isSessionRunning, canAddOutput: canAddOutput)
            self.performOnSessionQueue = performOnSessionQueue
        }
    }
}

final class CapturePhotoOutputSpy: AVCapturePhotoOutput {
    struct CapturePhotoParam {
        let settings: AVCapturePhotoSettings
        weak var delegate: AVCapturePhotoCaptureDelegate?
    }
    
    private var loggedCapturePhotoParams = [CapturePhotoParam]()
    var capturePhotoCallCount: Int {
        loggedCapturePhotoParams.count
    }
    var loggedSettings: [AVCapturePhotoSettings] {
        loggedCapturePhotoParams.map(\.settings)
    }
    var loggedDelegates: [AVCapturePhotoCaptureDelegate] {
        loggedCapturePhotoParams.compactMap(\.delegate)
    }
    
    override func capturePhoto(with settings: AVCapturePhotoSettings, delegate: AVCapturePhotoCaptureDelegate) {
        loggedCapturePhotoParams.append(CapturePhotoParam(settings: settings, delegate: delegate))
    }
}

extension CameraFlashMode {
    func toCaptureDeviceFlashMode() -> AVCaptureDevice.FlashMode {
        switch self {
        case .on: return .on
        case .off: return .off
        case .auto: return .auto
        }
    }
}

extension AVCapturePhoto {
    @objc convenience init(mock: String) {
        fatalError("should not come to here, swizzled by NSObject.init")
    }
    
    struct MethodPair {
        typealias Pair = (class: AnyClass, method: Selector)
        
        let from: Pair
        let to: Pair
    }
    
    static var instanceMethodPairs: [MethodPair] {
        [
            MethodPair(
                from: (class: AVCapturePhotoStub.self, method: #selector(AVCapturePhotoStub.init(mock:))),
                to: (class: AVCapturePhotoStub.self, method: #selector(NSObject.init))
            ),
            MethodPair(
                from: (class: AVCapturePhoto.self, method: #selector(AVCapturePhoto.init(mock:))),
                to: (class: AVCapturePhoto.self, method: #selector(AVCapturePhotoStub.init(mock:)))
            )
        ]
    }
    
    static func swizzled() {
        instanceMethodPairs.forEach { pair in
            method_exchangeImplementations(
                class_getInstanceMethod(pair.from.class, pair.from.method)!,
                class_getInstanceMethod(pair.to.class, pair.to.method)!
            )
        }
    }
    
    static func revertSwizzled() {
        instanceMethodPairs.forEach { pair in
            method_exchangeImplementations(
                class_getInstanceMethod(pair.to.class, pair.to.method)!,
                class_getInstanceMethod(pair.from.class, pair.from.method)!
            )
        }
    }
}

final class AVCapturePhotoStub: AVCapturePhoto {
    var fileData: Data?
    
    @objc convenience init(mock: String) {
        fatalError("should not come to here, swizzled by NSObject.init")
    }
    
    override func fileDataRepresentation() -> Data? {
        fileData
    }
}
