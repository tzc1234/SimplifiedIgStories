//
//  LocalFileManager.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 10/03/2022.
//

import UIKit

protocol FileManageable {
    func saveImage(_ image: UIImage, fileName: String) throws -> URL
    func getImage(for url: URL) -> UIImage?
    func deleteFile(by url: URL)
}

enum FileManageableError: Error {
    case saveFailed
}

final class LocalFileManager: FileManageable {
    func saveImage(_ image: UIImage, fileName: String) throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw FileManageableError.saveFailed
        }
        
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent("\(fileName).jpg")
        
        do {
            try data.write(to: url)
            return url
        } catch {
            throw FileManageableError.saveFailed
        }
    }
    
    func getImage(for url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
    
    func deleteFile(by url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            try FileManager.default.removeItem(at: url)
            print("Delete file at \(url.path) successful.")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
