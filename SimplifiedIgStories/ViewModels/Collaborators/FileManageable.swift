//
//  FileManageable.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 03/07/2024.
//

import UIKit

protocol FileManageable {
    func saveImage(_ image: UIImage, fileName: String) throws -> URL
    func getImage(for url: URL) -> UIImage?
    func delete(for url: URL) throws
}

enum FileManageableError: Error {
    case saveFailed
    case jpegConversionFailed
    case fileForDeletionNotFound
    case deleteFailed
}
