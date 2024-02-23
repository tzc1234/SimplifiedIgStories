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
}

extension PHPhotoLibrary {
    @objc static func returnDeniedAuthorization(for accessLevel: PHAccessLevel) async -> PHAuthorizationStatus {
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
