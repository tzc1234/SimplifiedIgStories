//
//  LocalMediaSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 09/02/2024.
//

import Foundation

protocol MediaSaver {
    func saveImageData(_ data: Data) async throws
    func saveVideo(by url: URL) async throws
}

enum MediaSaverError: Error {
    case noPermission
    case failed
}

final class LocalMediaSaver: MediaSaver {
    private let store: MediaStore
    
    init(store: MediaStore = PHPPhotoMediaStore()) {
        self.store = store
    }
    
    func saveImageData(_ data: Data) async throws {
        do {
            try await store.saveImageData(data)
        } catch MediaStoreError.noPermission {
            throw MediaSaverError.noPermission
        } catch {
            throw MediaSaverError.failed
        }
    }
    
    func saveVideo(by url: URL) async throws {
        do {
            try await store.saveVideo(for: url)
        } catch MediaStoreError.noPermission {
            throw MediaSaverError.noPermission
        } catch {
            throw MediaSaverError.failed
        }
    }
}
