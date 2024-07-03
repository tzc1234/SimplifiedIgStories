//
//  MediaSaver.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 03/07/2024.
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
