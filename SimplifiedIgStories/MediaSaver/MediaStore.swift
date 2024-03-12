//
//  MediaStore.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 09/02/2024.
//

import Foundation

protocol MediaStore {
    func saveImageData(_ data: Data) async throws
    func saveVideo(for url: URL) async throws
}

enum MediaStoreError: Error {
    case noPermission
    case failed
}
