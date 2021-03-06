//
//  LocalFileManager.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 10/03/2022.
//

import UIKit

// MARK: - FileManageable
protocol FileManageable {
    func saveImageToTemp(image: UIImage) -> URL?
    func getImageBy(url: URL) -> UIImage?
    func deleteFileBy(url: URL)
}

// MARK: - LocalFileManager
struct LocalFileManager: FileManageable {
    func saveImageToTemp(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("Error when getting image data.")
            return nil
        }
        
        let imageName = "img_\(UUID().uuidString)"
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent("\(imageName).jpg")
        
        do {
            try data.write(to: url)
            print("Saving image: \(imageName) successful.")
            return url
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getImageBy(url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
    
    func deleteFileBy(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            try FileManager.default.removeItem(at: url)
            print("Delete file at \(url.path) successful.")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
