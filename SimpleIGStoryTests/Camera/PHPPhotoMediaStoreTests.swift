//
//  PHPPhotoMediaStoreTests.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 23/02/2024.
//

import XCTest
import PhotosUI
@testable import Simple_IG_Story

final class PHPPhotoMediaStoreTests: XCTestCase {
    func test_saveImageData_deliversFailedErrorWithInvalidImageData() async {
        let sut = PHPPhotoMediaStore()
        let invalidData = Data("invalid".utf8)
        
        await assertThrowsError(try await sut.saveImageData(invalidData)) { error in
            XCTAssertEqual(error as? MediaStoreError, .failed)
        }
    }
    
    func test_saveImageData_deliversNoPermissionErrorIfUnauthorizedWithImageData() async {
        PHPhotoLibrary.swizzledToUnauthorizedPermission()
        let sut = PHPPhotoMediaStore()
        let imageData = UIImage.makeData(withColor: .red)
        
        await assertThrowsError(try await sut.saveImageData(imageData)) { error in
            XCTAssertEqual(error as? MediaStoreError, .noPermission)
        }
        PHPhotoLibrary.revertSwizzledToUnauthorizedPermission()
    }
    
    // Cannot mock PHAssetChangeRequest, therefore cannot test the happy path of saveImageData and saveVideo.
    
    func test_saveImageData_deliversFailedErrorWhenPerformChangeFailed() async {
        PHPhotoLibrary.swizzled()
        let sut = PHPPhotoMediaStore()
        let imageData = UIImage.makeData(withColor: .red)
        
        await assertThrowsError(try await sut.saveImageData(imageData)) { error in
            XCTAssertEqual(error as? MediaStoreError, .failed)
        }
        PHPhotoLibrary.revertSwizzled()
    }
    
    func test_saveVideo_deliversNoPermissionErrorIfUnauthorized() async {
        PHPhotoLibrary.swizzledToUnauthorizedPermission()
        let sut = PHPPhotoMediaStore()
        
        await assertThrowsError(try await sut.saveVideo(for: anyVideoURL())) { error in
            XCTAssertEqual(error as? MediaStoreError, .noPermission)
        }
        PHPhotoLibrary.revertSwizzledToUnauthorizedPermission()
    }
    
    func test_saveVideo_deliversFailedErrorWhenPerformChangeFailed() async {
        PHPhotoLibrary.swizzled()
        let sut = PHPPhotoMediaStore()
        
        await assertThrowsError(try await sut.saveVideo(for: anyVideoURL())) { error in
            XCTAssertEqual(error as? MediaStoreError, .failed)
        }
        PHPhotoLibrary.revertSwizzled()
    }
}

extension PHPhotoLibrary {
    @objc class func returnAuthorized(for accessLevel: PHAccessLevel) async -> PHAuthorizationStatus {
        accessLevel == .addOnly ? .authorized : .denied
    }
    
    @objc func _performChanges(_ changeBlock: @escaping () -> Void) async throws {
        throw anyNSError()
    }
    
    static func swizzled() {
        stub().swizzled()
    }
    
    static func revertSwizzled() {
        stub().revertSwizzled()
    }
    
    private static func stub() -> MethodSwizzlingStub {
        MethodSwizzlingStub(
            instanceMethodPairs: [
                .init(
                    from: (PHPhotoLibrary.self, #selector(PHPhotoLibrary.performChanges(_:))),
                    to: (PHPhotoLibrary.self, #selector(PHPhotoLibrary._performChanges(_:)))
                )
            ],
            classMethodPairs: [
                .init(
                    from: (PHPhotoLibrary.self, #selector(PHPhotoLibrary.requestAuthorization(for:))),
                    to: (PHPhotoLibrary.self, #selector(PHPhotoLibrary.returnAuthorized(for:)))
                )
            ]
        )
    }
}

extension PHPhotoLibrary {
    @objc class func returnDeniedAuthorization(for accessLevel: PHAccessLevel) async -> PHAuthorizationStatus {
        .denied
    }
    
    static func swizzledToUnauthorizedPermission() {
        deniedPermissionStub().swizzled()
    }
    
    static func revertSwizzledToUnauthorizedPermission() {
        deniedPermissionStub().revertSwizzled()
    }
    
    private static func deniedPermissionStub() -> MethodSwizzlingStub {
        MethodSwizzlingStub(
            instanceMethodPairs: [],
            classMethodPairs: [
                .init(
                    from: (PHPhotoLibrary.self, #selector(PHPhotoLibrary.requestAuthorization(for:))),
                    to: (PHPhotoLibrary.self, #selector(PHPhotoLibrary.returnDeniedAuthorization(for:)))
                )
            ]
        )
    }
}
