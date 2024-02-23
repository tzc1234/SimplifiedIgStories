//
//  LocalMediaSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 09/02/2024.
//

import Foundation

final class LocalMediaSaver {
    private let store: MediaStore
    
    init(store: MediaStore) {
        self.store = store
    }
    
    enum Error: Swift.Error {
        case noPermission
        case failed
    }
    
    func saveImageData(_ data: Data) async throws {
        do {
            try await store.saveImageData(data)
        } catch MediaStoreError.noPermission {
            throw Error.noPermission
        } catch {
            throw Error.failed
        }
    }
    
    func saveVideo(by url: URL) async throws {
        do {
            try await store.saveVideo(for: url)
        } catch MediaStoreError.noPermission {
            throw Error.noPermission
        } catch {
            throw Error.failed
        }
    }
}
