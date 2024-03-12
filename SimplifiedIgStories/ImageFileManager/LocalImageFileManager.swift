//
//  LocalImageFileManager.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 10/03/2022.
//

import UIKit

protocol ImageFileManageable {
    func saveImage(_ image: UIImage, fileName: String) throws -> URL
    func getImage(for url: URL) -> UIImage?
    func deleteImage(for url: URL) throws
}

enum ImageFileManageableError: Error {
    case saveFailed
    case jpegConversionFailed
    case fileForDeletionNotFound
    case deleteFailed
}

final class LocalImageFileManager: ImageFileManageable {
    private let directory: URL
    private let fileExtension: String
    
    init(directory: URL = FileManager.default.temporaryDirectory, fileExtension: String = "jpg") {
        self.directory = directory
        self.fileExtension = fileExtension
    }
    
    func saveImage(_ image: UIImage, fileName: String) throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ImageFileManageableError.jpegConversionFailed
        }
        
        let url = directory.appendingPathComponent("\(fileName)").appendingPathExtension(fileExtension)
        
        do {
            try data.write(to: url)
            return url
        } catch {
            throw ImageFileManageableError.saveFailed
        }
    }
    
    func getImage(for url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
    
    func deleteImage(for url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ImageFileManageableError.fileForDeletionNotFound
        }
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw ImageFileManageableError.deleteFailed
        }
    }
}
