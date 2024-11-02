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
    
    // In iOS 18, seems that mocking `PHPhotoLibrary.performChanges` does not work anymore,
    // therefore I can only remove those tests involve `PHPhotoLibrary.performChanges`.
    
    func test_saveVideo_deliversNoPermissionErrorIfUnauthorized() async {
        PHPhotoLibrary.swizzledToUnauthorizedPermission()
        let sut = PHPPhotoMediaStore()
        
        await assertThrowsError(try await sut.saveVideo(for: anyVideoURL())) { error in
            XCTAssertEqual(error as? MediaStoreError, .noPermission)
        }
        PHPhotoLibrary.revertSwizzledToUnauthorizedPermission()
    }
}

extension PHPhotoLibrary {
    @objc class func _requestAuthorization(for accessLevel: PHAccessLevel) async -> PHAuthorizationStatus {
        accessLevel == .addOnly ? .authorized : .denied
    }
    
    static func revertSwizzledToPerformChangesFailure() {
        stub().revertSwizzled()
    }
    
    private static func stub() -> MethodSwizzlingStub {
        MethodSwizzlingStub(
            classMethodPairs: [
                MethodPair(
                    from: (PHPhotoLibrary.self, #selector(PHPhotoLibrary.requestAuthorization(for:))),
                    to: (PHPhotoLibrary.self, #selector(PHPhotoLibrary._requestAuthorization(for:)))
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
            classMethodPairs: [
                MethodPair(
                    from: (PHPhotoLibrary.self, #selector(PHPhotoLibrary.requestAuthorization(for:))),
                    to: (PHPhotoLibrary.self, #selector(PHPhotoLibrary.returnDeniedAuthorization(for:)))
                )
            ]
        )
    }
}
