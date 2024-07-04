//
//  MediaSaverSpy.swift
//  SimpleIGStoryTests
//
//  Created by Tsz-Lung on 04/07/2024.
//

import Foundation
@testable import Simple_IG_Story

final class MediaSaverSpy: MediaSaver {
    private(set) var saveImageDataCallCount = 0
    private(set) var saveVideoCallCount = 0
    
    private let saveImageDataStub: () async throws -> Void
    private let saveVideoStub: () async throws -> Void
    
    init(saveImageDataStub: @escaping () async throws -> Void = {},
         saveVideoStub: @escaping () async throws -> Void = {}) {
        self.saveImageDataStub = saveImageDataStub
        self.saveVideoStub = saveVideoStub
    }
    
    func saveImageData(_ data: Data) async throws {
        saveImageDataCallCount += 1
        try await saveImageDataStub()
    }
    
    func saveVideo(by url: URL) async throws {
        saveVideoCallCount += 1
        try await saveVideoStub()
    }
}
